import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/notification/data/models/notification_model.dart';
import 'package:eticketing_helpdesk/features/notification/data/repositories/notification_repository.dart';

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
      NotificationNotifier.new,
    );

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return [];
    return ref.read(notificationRepositoryProvider).fetchAll(user.id);
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    state = AsyncData(
      state.value
              ?.map((n) => n.id == id ? n.copyWith(isRead: true) : n)
              .toList() ??
          [],
    );
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    state = AsyncData(
      state.value?.map((n) => n.copyWith(isRead: true)).toList() ?? [],
    );
  }

  int get unreadCount => state.value?.where((n) => !n.isRead).length ?? 0;
}

final unreadCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationProvider)
          .value
          ?.where((n) => !n.isRead)
          .length ??
      0;
});
