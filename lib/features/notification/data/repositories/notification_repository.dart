import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/features/notification/data/models/notification_model.dart';

class NotificationRepository {
  // ─── Fetch notifikasi milik user (max 50, terbaru dulu) ───
  Future<List<NotificationModel>> fetchAll(String userId) async {
    final data = await SupabaseService.from(SupabaseTables.notifications)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (data as List)
        .map((m) => NotificationModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // ─── Tandai satu notifikasi sebagai sudah dibaca ──────────
  Future<void> markAsRead(String notificationId) async {
    await SupabaseService.from(SupabaseTables.notifications)
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  // ─── Tandai semua notifikasi user sebagai sudah dibaca ────
  Future<void> markAllAsRead(String userId) async {
    await SupabaseService.from(SupabaseTables.notifications)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  // ─── Hitung unread count (untuk badge) ───────────────────
  Future<int> unreadCount(String userId) async {
    final data = await SupabaseService.from(SupabaseTables.notifications)
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);
    return (data as List).length;
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});
