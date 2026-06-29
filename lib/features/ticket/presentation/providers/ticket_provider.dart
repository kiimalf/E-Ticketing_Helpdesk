import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
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

// ─── Ticket List Provider ─────────────────────────────────────
final ticketListProvider =
    AsyncNotifierProvider<TicketListNotifier, List<TicketModel>>(
      TicketListNotifier.new,
    );

class TicketListNotifier extends AsyncNotifier<List<TicketModel>> {
  @override
  Future<List<TicketModel>> build() async {
    // Re-fetch ketika filter berubah (watch)
    final filter = ref.watch(ticketFilterProvider);
    final user = ref.watch(authProvider).value;
    final helpdeskOnlyAssigned = ref.watch(helpdeskAssignedFilterProvider);

    final createdById = user?.role == UserRole.user ? user?.id : null;

    // Helpdesk: default hanya lihat tiket yang ditugaskan kepadanya
    String? assignedTo = filter.assignedToId;
    if (user?.role == UserRole.helpdesk && helpdeskOnlyAssigned) {
      assignedTo = user?.id;
    }

    return ref
        .read(ticketRepositoryProvider)
        .fetchTickets(
          status: filter.status,
          priority: filter.priority,
          search: filter.search.isNotEmpty ? filter.search : null,
          createdById: createdById,
          assignedToId: assignedTo,
        );
  }
}

// ─── Ticket Detail Provider ───────────────────────────────────
final ticketDetailProvider = FutureProvider.family<TicketModel, String>((
  ref,
  id,
) {
  return ref.read(ticketRepositoryProvider).fetchTicketById(id);
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
    List<File> attachments = const [],
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
      ref.invalidate(ticketListProvider);
    }

    return result.hasValue;
  }
}

// ─── Dashboard Stats Provider ─────────────────────────────────
final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authProvider).value;
  final userId = user?.role == UserRole.user ? user?.id : null;
  return ref.read(ticketRepositoryProvider).fetchStats(userId: userId);
});

// ─── Recent Tickets (dashboard) ───────────────────────────────
final recentTicketsProvider = FutureProvider.autoDispose<List<TicketModel>>((
  ref,
) async {
  final user = ref.watch(authProvider).value;
  final userId = user?.role == UserRole.user ? user?.id : null;

  final all = await ref
      .read(ticketRepositoryProvider)
      .fetchTickets(createdById: userId);

  return all.take(5).toList();
});
