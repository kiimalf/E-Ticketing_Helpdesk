import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_comment_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_attachment_model.dart';

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final String createdById;
  final String? createdByName;
  final String? assignedToId;
  final String? assignedToName;
  final List<TicketCommentModel> comments;
  final List<TicketAttachmentModel> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  const TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdById,
    this.createdByName,
    this.assignedToId,
    this.assignedToName,
    this.comments    = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
  });

  // ─── Factory: dari Map Supabase (dengan join) ─────────────
  factory TicketModel.fromMap(Map<String, dynamic> map) {
    final creator  = map['creator']  as Map<String, dynamic>?;
    final assignee = map['assignee'] as Map<String, dynamic>?;

    final rawComments    = map['ticket_comments']    as List<dynamic>? ?? [];
    final rawAttachments = map['ticket_attachments'] as List<dynamic>? ?? [];

    return TicketModel(
      id:             map['id']            as String,
      ticketNumber:   map['ticket_number'] as String,
      title:          map['title']         as String,
      description:    map['description']   as String,
      status:         TicketStatusX.fromString(map['status']   as String?),
      priority:       TicketPriorityX.fromString(map['priority'] as String?),
      category:       (map['category']    as String?) ?? 'Lainnya',
      createdById:    map['created_by']   as String,
      createdByName:  creator?['name']    as String?,
      assignedToId:   map['assigned_to']  as String?,
      assignedToName: assignee?['name']   as String?,
      comments: rawComments
          .map((c) => TicketCommentModel.fromMap(c as Map<String, dynamic>))
          .toList(),
      attachments: rawAttachments
          .map((a) => TicketAttachmentModel.fromMap(a as Map<String, dynamic>))
          .toList(),
      createdAt:  DateTime.parse(map['created_at'] as String),
      updatedAt:  DateTime.parse(map['updated_at'] as String),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.parse(map['resolved_at'] as String)
          : null,
    );
  }

  // ─── toMap untuk INSERT ───────────────────────────────────
  Map<String, dynamic> toInsertMap() => {
        'title':       title,
        'description': description,
        'status':      TicketStatus.open.dbValue,
        'priority':    priority.name,
        'category':    category,
        'created_by':  createdById,
      };

  // ─── copyWith ─────────────────────────────────────────────
  TicketModel copyWith({
    TicketStatus?              status,
    String?                    assignedToId,
    String?                    assignedToName,
    List<TicketCommentModel>?  comments,
    List<TicketAttachmentModel>? attachments,
    DateTime?                  resolvedAt,
  }) =>
      TicketModel(
        id:             id,
        ticketNumber:   ticketNumber,
        title:          title,
        description:    description,
        status:         status         ?? this.status,
        priority:       priority,
        category:       category,
        createdById:    createdById,
        createdByName:  createdByName,
        assignedToId:   assignedToId   ?? this.assignedToId,
        assignedToName: assignedToName ?? this.assignedToName,
        comments:       comments       ?? this.comments,
        attachments:    attachments    ?? this.attachments,
        createdAt:      createdAt,
        updatedAt:      DateTime.now(),
        resolvedAt:     resolvedAt     ?? this.resolvedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TicketModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
