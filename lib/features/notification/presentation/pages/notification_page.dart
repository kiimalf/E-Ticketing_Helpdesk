import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';

import 'package:eticketing_helpdesk/features/notification/presentation/providers/notification_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:intl/intl.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  IconData _icon(NotificationType t) => switch (t) {
    NotificationType.ticketCreated => Icons.add_circle_outline_rounded,
    NotificationType.statusUpdated => Icons.sync_rounded,
    NotificationType.newComment => Icons.chat_bubble_outline_rounded,
    NotificationType.ticketAssigned => Icons.assignment_ind_outlined,
  };

  Color _color(NotificationType t) => switch (t) {
    NotificationType.ticketCreated => AppColors.statusResolved,
    NotificationType.statusUpdated => AppColors.statusInProgress,
    NotificationType.newComment => AppColors.primary,
    NotificationType.ticketAssigned => AppColors.priorityCritical,
  };

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifAsync = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          notifAsync.maybeWhen(
            data: (list) => list.any((n) => !n.isRead)
                ? TextButton(
                    onPressed: notifier.markAllAsRead,
                    child: const Text('Baca Semua'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(notificationProvider),
        ),
        data: (list) => list.isEmpty
            ? const AppEmptyState(
                title: 'Tidak ada notifikasi',
                subtitle: 'Notifikasi tiket akan muncul di sini',
                icon: Icons.notifications_none_rounded,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final n = list[i];
                  final color = _color(n.type);

                  return InkWell(
                    onTap: () {
                      notifier.markAsRead(n.id);
                      if (n.ticketId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TicketDetailPage(ticketId: n.ticketId!),
                          ),
                        );
                      }
                    },
                    child: Container(
                      color: n.isRead
                          ? Colors.transparent
                          : AppColors.primary.withValues(alpha: 0.04),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_icon(n.type), color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: n.isRead
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    if (!n.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(n.body, style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 5),
                                Text(
                                  _ago(n.createdAt),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
