import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/notification/data/models/notification_model.dart';
import 'package:eticketing_helpdesk/features/notification/data/repositories/notification_repository.dart';

final notificationProvider =
    StreamNotifierProvider<NotificationNotifier, List<NotificationModel>>(
      NotificationNotifier.new,
    );

class NotificationNotifier extends StreamNotifier<List<NotificationModel>> {
  @override
  Stream<List<NotificationModel>> build() {
    final user = ref.watch(authProvider).value;
    if (user == null) return Stream.value([]);
    return ref.read(notificationRepositoryProvider).streamAll(user.id);
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    // Tidak perlu update state manual karena stream akan memicu build() ulang
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
  }
}

final unreadCountProvider = Provider<int>((ref) {
  return ref
          .watch(notificationProvider)
          .value
          ?.where((n) => !n.isRead)
          .length ??
      0;
});
