import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/repositories/ticket_repository.dart';

// ─── Filter State ─────────────────────────────────────────────
class TicketFilter {
  final TicketStatus?   status;
  final TicketPriority? priority;
  final String          search;

  const TicketFilter({
    this.status,
    this.priority,
    this.search = '',
  });

  bool get hasFilter =>
      status != null || priority != null || search.isNotEmpty;

  TicketFilter copyWith({
    TicketStatus?   status,
    TicketPriority? priority,
    String?         search,
    bool clearStatus   = false,
    bool clearPriority = false,
  }) =>
      TicketFilter(
        status:   clearStatus   ? null : (status   ?? this.status),
        priority: clearPriority ? null : (priority ?? this.priority),
        search:   search ?? this.search,
      );
}

// ─── Filter Provider ──────────────────────────────────────────
final ticketFilterProvider =
    StateNotifierProvider<TicketFilterNotifier, TicketFilter>((ref) {
  return TicketFilterNotifier();
});

class TicketFilterNotifier extends StateNotifier<TicketFilter> {
  TicketFilterNotifier() : super(const TicketFilter());

  void setStatus(TicketStatus? s) =>
      state = state.copyWith(status: s, clearStatus: s == null);

  void setPriority(TicketPriority? p) =>
      state = state.copyWith(priority: p, clearPriority: p == null);

  void setSearch(String q) => state = state.copyWith(search: q);

  void clear() => state = const TicketFilter();
}

// ─── Ticket List Provider ─────────────────────────────────────
final ticketListProvider =
    AsyncNotifierProvider.autoDispose<TicketListNotifier, List<TicketModel>>(
        TicketListNotifier.new);

class TicketListNotifier
    extends AutoDisposeAsyncNotifier<List<TicketModel>> {
  @override
  Future<List<TicketModel>> build() async {
    // Re-fetch ketika filter berubah (watch)
    final filter = ref.watch(ticketFilterProvider);
    final user   = ref.watch(authProvider).valueOrNull;

    final createdById =
        user?.role == UserRole.user ? user?.id : null;

    return ref.read(ticketRepositoryProvider).fetchTickets(
          status:      filter.status,
          priority:    filter.priority,
          search:      filter.search.isNotEmpty ? filter.search : null,
          createdById: createdById,
        );
  }
}

// ─── Ticket Detail Provider ───────────────────────────────────
final ticketDetailProvider = AsyncNotifierProvider.autoDispose
    .family<TicketDetailNotifier, TicketModel, String>(
        TicketDetailNotifier.new);

class TicketDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<TicketModel, String> {
  @override
  Future<TicketModel> build(String arg) async {
    return ref.read(ticketRepositoryProvider).fetchTicketById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(ticketRepositoryProvider).fetchTicketById(arg));
  }

  Future<bool> addComment(String content, String authorId) async {
    final comment = await ref.read(ticketRepositoryProvider).addComment(
          ticketId: arg,
          authorId: authorId,
          content:  content,
        );

    // Update state lokal tanpa refetch
    state = state.whenData((ticket) {
      return ticket.copyWith(
          comments: [...ticket.comments, comment]);
    });

    return true;
  }

  Future<void> updateStatus(TicketStatus newStatus) async {
    await ref.read(ticketRepositoryProvider).updateStatus(arg, newStatus);
    state = state.whenData(
        (t) => t.copyWith(status: newStatus));
    // Invalidate list supaya refresh
    ref.invalidate(ticketListProvider);
  }
}

// ─── Create Ticket Provider ───────────────────────────────────
final createTicketProvider =
    AsyncNotifierProvider.autoDispose<CreateTicketNotifier, void>(
        CreateTicketNotifier.new);

class CreateTicketNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String title,
    required String description,
    required TicketPriority priority,
    required String category,
    List<File> attachments = const [],
  }) async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return false;

    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => ref.read(ticketRepositoryProvider).createTicket(
            title:       title,
            description: description,
            priority:    priority,
            category:    category,
            createdById: user.id,
            attachments: attachments,
          ),
    );

    state = result.when(
      data:    (_) => const AsyncData(null),
      loading: ()  => const AsyncLoading(),
      error:   (e, s) => AsyncError(e, s),
    );

    if (result.hasValue) {
      ref.invalidate(ticketListProvider);
    }

    return result.hasValue;
  }
}

// ─── Dashboard Stats Provider ─────────────────────────────────
final dashboardStatsProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  final userId =
      user?.role == UserRole.user ? user?.id : null;
  return ref.read(ticketRepositoryProvider).fetchStats(userId: userId);
});

// ─── Recent Tickets (dashboard) ───────────────────────────────
final recentTicketsProvider =
    FutureProvider.autoDispose<List<TicketModel>>((ref) async {
  final user = ref.watch(authProvider).valueOrNull;
  final userId =
      user?.role == UserRole.user ? user?.id : null;

  final all = await ref
      .read(ticketRepositoryProvider)
      .fetchTickets(createdById: userId);

  return all.take(5).toList();
});
