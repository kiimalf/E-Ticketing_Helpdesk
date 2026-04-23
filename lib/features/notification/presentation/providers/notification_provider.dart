import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/notification/data/models/notification_model.dart';
import 'package:eticketing_helpdesk/features/notification/data/repositories/notification_repository.dart';

final notificationProvider = AsyncNotifierProvider.autoDispose<
    NotificationNotifier, List<NotificationModel>>(NotificationNotifier.new);

class NotificationNotifier
    extends AutoDisposeAsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final user = ref.watch(authProvider).valueOrNull;
    if (user == null) return [];
    return ref.read(notificationRepositoryProvider).fetchAll(user.id);
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    state = AsyncData(
      state.valueOrNull
              ?.map((n) => n.id == id ? n.copyWith(isRead: true) : n)
              .toList() ??
          [],
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) return;
    await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    state = AsyncData(
      state.valueOrNull?.map((n) => n.copyWith(isRead: true)).toList() ?? [],
    );
  }

  int get unreadCount =>
      state.valueOrNull?.where((n) => !n.isRead).length ?? 0;
}

final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(notificationProvider)
          .valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;
});
