import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_comment_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_attachment_model.dart';
import 'package:eticketing_helpdesk/features/dashboard/data/models/dashboard_stats_model.dart';

class TicketRepository {
  final _uuid = const Uuid();

  // ─── Query SELECT dengan JOIN ─────────────────────────────
  static const String _selectWithJoins = '''
    *,
    creator:profiles!tickets_created_by_fkey(id, name, avatar_url, role),
    assignee:profiles!tickets_assigned_to_fkey(id, name, avatar_url, role),
    ticket_comments(
      id, ticket_id, author_id, content, is_internal, created_at,
      profiles(id, name, avatar_url, role)
    ),
    ticket_attachments(
      id, ticket_id, file_name, file_url, file_type, file_size, uploaded_by, uploaded_at
    )
  ''';

  // ─── Fetch daftar tiket ───────────────────────────────────
  Future<List<TicketModel>> fetchTickets({
    TicketStatus? status,
    TicketPriority? priority,
    String? search,
    String? createdById, // null = semua (untuk helpdesk/admin)
    String? assignedToId, // untuk filter admin
  }) async {
    var query = SupabaseService.from(
      SupabaseTables.tickets,
    ).select(_selectWithJoins);

    // Filter status
    if (status != null) {
      query = query.eq('status', status.dbValue);
    }
    // Filter priority
    if (priority != null) {
      query = query.eq('priority', priority.name);
    }
    // Filter by creator (untuk role user)
    if (createdById != null) {
      query = query.eq('created_by', createdById);
    }
    // Filter by assigned to (untuk admin)
    if (assignedToId != null) {
      query = query.eq('assigned_to', assignedToId);
    }
    // Pencarian teks
    if (search != null && search.isNotEmpty) {
      query = query.or('title.ilike.%$search%,ticket_number.ilike.%$search%');
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((m) => TicketModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // ─── Fetch satu tiket by ID ───────────────────────────────
  Future<TicketModel> fetchTicketById(String id) async {
    final data = await SupabaseService.from(
      SupabaseTables.tickets,
    ).select(_selectWithJoins).eq('id', id).single();

    return TicketModel.fromMap(data);
  }

  // ─── Buat tiket baru ──────────────────────────────────────
  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required TicketPriority priority,
    required String category,
    required String createdById,
    List<File> attachments = const [],
  }) async {
    // 1. Insert tiket
    final result = await SupabaseService.from(SupabaseTables.tickets)
        .insert({
          'title': title,
          'description': description,
          'status': TicketStatus.open.dbValue,
          'priority': priority.name,
          'category': category,
          'created_by': createdById,
        })
        .select()
        .single();

    final ticketId = result['id'] as String;

    // 2. Upload lampiran (jika ada)
    for (final file in attachments) {
      await uploadAttachment(
        ticketId: ticketId,
        file: file,
        uploadedBy: createdById,
      );
    }

    // 3. Kembalikan tiket lengkap dengan join
    return fetchTicketById(ticketId);
  }

  // ─── Update status tiket ──────────────────────────────────
  Future<void> updateStatus(String ticketId, TicketStatus newStatus) async {
    final updates = <String, dynamic>{
      'status': newStatus.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (newStatus == TicketStatus.resolved) {
      updates['resolved_at'] = DateTime.now().toIso8601String();
    }

    await SupabaseService.from(
      SupabaseTables.tickets,
    ).update(updates).eq('id', ticketId);
  }

  // ─── Assign tiket ke staff ────────────────────────────────
  Future<void> assignTicket(String ticketId, String assigneeId) async {
    await SupabaseService.from(SupabaseTables.tickets)
        .update({
          'assigned_to': assigneeId,
          'status': TicketStatus.inProgress.dbValue,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', ticketId);
  }

  // ─── Tambah komentar ──────────────────────────────────────
  Future<TicketCommentModel> addComment({
    required String ticketId,
    required String authorId,
    required String content,
    bool isInternal = false,
  }) async {
    final data = await SupabaseService.from(SupabaseTables.comments)
        .insert({
          'ticket_id': ticketId,
          'author_id': authorId,
          'content': content,
          'is_internal': isInternal,
        })
        .select('''
          id, ticket_id, author_id, content, is_internal, created_at,
          profiles(id, name, avatar_url, role)
        ''')
        .single();

    // Bump updated_at tiket
    await SupabaseService.from(SupabaseTables.tickets)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', ticketId);

    return TicketCommentModel.fromMap(data);
  }

  // ─── Upload lampiran ke Supabase Storage ──────────────────
  Future<TicketAttachmentModel> uploadAttachment({
    required String ticketId,
    required File file,
    required String uploadedBy,
  }) async {
    final ext = p.extension(file.path).toLowerCase();
    final storagePath = 'tickets/$ticketId/${_uuid.v4()}$ext';

    // Upload ke bucket
    await SupabaseService.bucket(
      SupabaseBuckets.ticketAttachments,
    ).upload(storagePath, file);

    // Dapatkan public URL
    final fileUrl = SupabaseService.getPublicUrl(
      SupabaseBuckets.ticketAttachments,
      storagePath,
    );

    final isImage = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
    final fileSize = await file.length();

    // Simpan metadata attachment
    final data = await SupabaseService.from(SupabaseTables.attachments)
        .insert({
          'ticket_id': ticketId,
          'file_name': p.basename(file.path),
          'file_url': fileUrl,
          'file_type': isImage ? 'image' : 'file',
          'file_size': fileSize,
          'uploaded_by': uploadedBy,
        })
        .select()
        .single();

    return TicketAttachmentModel.fromMap(data);
  }

  // ─── Dashboard stats ──────────────────────────────────────
  Future<DashboardStatsModel> fetchStats({String? userId}) async {
    var query = SupabaseService.from(SupabaseTables.tickets).select('status');

    if (userId != null) {
      query = query.eq('created_by', userId);
    }

    final data = await query;
    return DashboardStatsModel.fromRows(data as List);
  }
}

// ─── Riverpod Provider ────────────────────────────────────────
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});
