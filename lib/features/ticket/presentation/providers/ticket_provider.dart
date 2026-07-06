import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_history_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/repositories/ticket_repository.dart';

// ─── Filter State ─────────────────────────────────────────────
class TicketFilter {
  final TicketStatus? status;
  final TicketPriority? priority;
  final String search;
  final String? assignedToId;

  const TicketFilter({
    this.status,
    this.priority,
    this.search = '',
    this.assignedToId,
  });

  bool get hasFilter =>
      status != null ||
      priority != null ||
      search.isNotEmpty ||
      assignedToId != null;

  TicketFilter copyWith({
    TicketStatus? status,
    TicketPriority? priority,
    String? search,
    String? assignedToId,
    bool clearStatus = false,
    bool clearPriority = false,
    bool clearAssignedTo = false,
  }) => TicketFilter(
    status: clearStatus ? null : (status ?? this.status),
    priority: clearPriority ? null : (priority ?? this.priority),
    search: search ?? this.search,
    assignedToId: clearAssignedTo ? null : (assignedToId ?? this.assignedToId),
  );
}

// ─── Filter Provider ──────────────────────────────────────────
final ticketFilterProvider =
    NotifierProvider<TicketFilterNotifier, TicketFilter>(
      TicketFilterNotifier.new,
    );

class TicketFilterNotifier extends Notifier<TicketFilter> {
  @override
  TicketFilter build() => const TicketFilter();

  void setStatus(TicketStatus? s) =>
      state = state.copyWith(status: s, clearStatus: s == null);

  void setPriority(TicketPriority? p) =>
      state = state.copyWith(priority: p, clearPriority: p == null);

  void setSearch(String q) => state = state.copyWith(search: q);

  void setAssignedTo(String? id) =>
      state = state.copyWith(assignedToId: id, clearAssignedTo: id == null);

  void clear() => state = const TicketFilter();
}

// ─── Helpdesk: Toggle filter tiket yang ditugaskan ────────────
final helpdeskAssignedFilterProvider =
    NotifierProvider<HelpdeskAssignedFilterNotifier, bool>(
      HelpdeskAssignedFilterNotifier.new,
    );

class HelpdeskAssignedFilterNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void updateState(bool value) => state = value;
}

final ticketListProvider =
    StreamNotifierProvider<TicketListNotifier, List<TicketModel>>(
      TicketListNotifier.new,
    );

class TicketListNotifier extends StreamNotifier<List<TicketModel>> {
  @override
  Stream<List<TicketModel>> build() async* {
    final filter = ref.watch(ticketFilterProvider);
    final user = ref.watch(authProvider).value;
    final helpdeskOnlyAssigned = ref.watch(helpdeskAssignedFilterProvider);

    final createdById = user?.role == UserRole.user ? user?.id : null;

    String? assignedTo = filter.assignedToId;
    if (user?.role == UserRole.helpdesk && helpdeskOnlyAssigned) {
      assignedTo = user?.id;
    }

    Future<List<TicketModel>> fetchAll() => ref
        .read(ticketRepositoryProvider)
        .fetchTickets(
          status: filter.status,
          priority: filter.priority,
          search: filter.search.isNotEmpty ? filter.search : null,
          createdById: createdById,
          assignedToId: assignedTo,
        );

    // Yield initial data
    yield await fetchAll();

    // Setup Supabase Realtime listener untuk tabel tickets
    final channel = Supabase.instance.client.channel('public:tickets:list');
    
    // Kita gunakan StreamController untuk mengubah callback menjadi stream
    final StreamController<void> controller = StreamController<void>();

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'tickets',
      callback: (payload) {
        if (!controller.isClosed) {
          controller.add(null);
        }
      },
    ).subscribe();

    // Pastikan channel berhenti mendengarkan saat provider di-dispose
    ref.onDispose(() {
      Supabase.instance.client.removeChannel(channel);
      controller.close();
    });

    // Setiap kali ada perubahan di tabel tickets, ambil ulang data
    await for (final _ in controller.stream) {
      yield await fetchAll();
    }
  }
}

// ─── Ticket Detail Provider ───────────────────────────────────
final ticketDetailProvider = FutureProvider.family<TicketModel, String>((
  ref,
  id,
) {
  return ref.read(ticketRepositoryProvider).fetchTicketById(id);
});

// ─── Ticket History Provider ──────────────────────────────────
final ticketHistoryProvider =
    FutureProvider.family<List<TicketHistoryModel>, String>((ref, ticketId) {
  return ref.read(ticketRepositoryProvider).fetchTicketHistory(ticketId);
});

// ─── Create Ticket Provider ───────────────────────────────────
final createTicketProvider = AsyncNotifierProvider<CreateTicketNotifier, void>(
  CreateTicketNotifier.new,
);

class CreateTicketNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String title,
    required String description,
    required TicketPriority priority,
    required String category,
    List<XFile> attachments = const [],
  }) async {
    final user = ref.read(authProvider).value;
    if (user == null) return false;

    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref
          .read(ticketRepositoryProvider)
          .createTicket(
            title: title,
            description: description,
            priority: priority,
            category: category,
            createdById: user.id,
            attachments: attachments,
          ),
    );

    state = result.when(
      data: (_) => const AsyncData(null),
      loading: () => const AsyncLoading(),
      error: (e, s) => AsyncError(e, s),
    );

    if (result.hasValue) {
      // Invalidate provider tiket agar me-refresh secara lokal tanpa menunggu websocket
      ref.invalidate(ticketListProvider);
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(recentTicketsProvider);
    }

    return result.hasValue;
  }
}

// ─── Shared Realtime Trigger ──────────────────────────────────
final ticketRealtimeChangesProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final StreamController<DateTime> controller = StreamController<DateTime>();
  final channel = Supabase.instance.client.channel('public:tickets:changes');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'tickets',
    callback: (payload) {
      if (!controller.isClosed) controller.add(DateTime.now());
    },
  ).subscribe();

  ref.onDispose(() {
    Supabase.instance.client.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});

// ─── Dashboard Stats Provider ─────────────────────────────────
final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  // Dengarkan perubahan realtime dari tabel tickets
  ref.watch(ticketRealtimeChangesProvider);

  final user = ref.watch(authProvider).value;

  // Role-based filtering:
  // - User: hanya tiket milik sendiri (created_by)
  // - Helpdesk: hanya tiket yang ditugaskan (assigned_to)
  // - Admin: semua tiket
  final userId = user?.role == UserRole.user ? user?.id : null;
  final assignedToId = user?.role == UserRole.helpdesk ? user?.id : null;

  return ref.read(ticketRepositoryProvider).fetchStats(
    userId: userId,
    assignedToId: assignedToId,
  );
});

// ─── Recent Tickets (dashboard) ───────────────────────────────
final recentTicketsProvider = FutureProvider.autoDispose<List<TicketModel>>((
  ref,
) async {
  // Dengarkan perubahan realtime dari tabel tickets
  ref.watch(ticketRealtimeChangesProvider);

  final user = ref.watch(authProvider).value;

  // Role-based filtering:
  // - User: hanya tiket milik sendiri (created_by)
  // - Helpdesk: hanya tiket yang ditugaskan (assigned_to)
  // - Admin: semua tiket
  final createdById = user?.role == UserRole.user ? user?.id : null;
  final assignedToId = user?.role == UserRole.helpdesk ? user?.id : null;

  final all = await ref
      .read(ticketRepositoryProvider)
      .fetchTickets(createdById: createdById, assignedToId: assignedToId);

  return all.take(5).toList();
});

