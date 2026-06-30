import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_comment_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_attachment_model.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/models/ticket_history_model.dart';
import 'package:eticketing_helpdesk/features/ticket/data/repositories/ticket_repository.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:eticketing_helpdesk/features/user/presentation/providers/user_provider.dart';

class TicketDetailPage extends ConsumerStatefulWidget {
  const TicketDetailPage({super.key, required this.ticketId});
  final String ticketId;

  @override
  ConsumerState<TicketDetailPage> createState() => _TicketDetailPageState();
}

// ignore_for_file: deprecated_member_use, use_build_context_synchronously, unnecessary_null_comparison
class _TicketDetailPageState extends ConsumerState<TicketDetailPage> {
  final _commentCtrl = TextEditingController();

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final comment = await ref
        .read(ticketRepositoryProvider)
        .addComment(
          ticketId: widget.ticketId,
          content: text,
          authorId: user.id,
        );

    if (comment != null) {
      ref.invalidate(ticketDetailProvider(widget.ticketId));
      ref.invalidate(ticketHistoryProvider(widget.ticketId));
      _commentCtrl.clear();
    }
  }

  void _showStatusSheet(TicketModel ticket) {
    final user = ref.read(authProvider).value;
    final isHelpdesk = user?.role == UserRole.helpdesk;

    // Helpdesk hanya bisa update tiket yang ditugaskan kepadanya
    if (isHelpdesk && ticket.assignedToId != user?.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda hanya bisa mengubah status tiket yang ditugaskan kepada Anda'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update Status', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...TicketStatus.values.map(
              (s) => RadioListTile<TicketStatus>(
                value: s,
                groupValue: ticket.status,
                title: Text(s.label),
                secondary: StatusBadge(status: s, small: true),
                onChanged: (v) async {
                  Navigator.pop(ctx);
                  if (v != null) {
                    final currentUser = ref.read(authProvider).value;
                    await ref
                        .read(ticketRepositoryProvider)
                        .updateStatus(
                          widget.ticketId,
                          v,
                          oldStatus: ticket.status,
                          performedBy: currentUser?.id,
                        );
                    ref.invalidate(ticketDetailProvider(widget.ticketId));
                    ref.invalidate(ticketHistoryProvider(widget.ticketId));
                    ref.invalidate(ticketListProvider);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAssignSheet(TicketModel ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, sheetRef, _) {
          final usersAsync = sheetRef.watch(userManagementProvider);
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tugaskan ke Helpdesk',
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                usersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Gagal memuat data helpdesk: $e')),
                  data: (users) {
                    final helpdesks = users
                        .where((u) => u.role == UserRole.helpdesk && u.isActive)
                        .toList();
                    if (helpdesks.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada helpdesk aktif'),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: helpdesks.length,
                      itemBuilder: (context, index) {
                        final h = helpdesks[index];
                        final isAssigned = ticket.assignedToName == h.name;
                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(h.name),
                          trailing: isAssigned
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final currentUser = ref.read(authProvider).value;
                            Navigator.pop(ctx);
                            try {
                              await ref
                                  .read(ticketRepositoryProvider)
                                  .assignTicket(
                                    widget.ticketId,
                                    h.id,
                                    assigneeName: h.name,
                                    performedBy: currentUser?.id,
                                  );
                              ref.invalidate(
                                ticketDetailProvider(widget.ticketId),
                              );
                              ref.invalidate(
                                ticketHistoryProvider(widget.ticketId),
                              );
                              ref.invalidate(ticketListProvider);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Tiket ditugaskan ke ${h.name}',
                                  ),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Gagal assign tiket: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(TicketModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Hapus Tiket',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus tiket ini?',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.ticketNumber,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ticket.title,
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Semua data terkait (komentar, lampiran, riwayat) akan ikut terhapus. Tindakan ini tidak dapat dibatalkan.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              try {
                await ref
                    .read(ticketRepositoryProvider)
                    .deleteTicket(widget.ticketId);
                ref.invalidate(ticketListProvider);
                ref.invalidate(dashboardStatsProvider);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Tiket berhasil dihapus'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                navigator.pop();
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus tiket: $e'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));
    final user = ref.watch(authProvider).value;
    final isStaff = user?.role != UserRole.user;

    return Scaffold(
      appBar: AppBar(
        title: ticketAsync.maybeWhen(
          data: (t) => Text(t.ticketNumber),
          orElse: () => const Text('Detail Tiket'),
        ),
        actions: [
          if (isStaff && user?.role == UserRole.admin)
            ticketAsync.maybeWhen(
              data: (t) => IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus Tiket',
                onPressed: () => _showDeleteDialog(t),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          if (isStaff && user?.role == UserRole.admin)
            ticketAsync.maybeWhen(
              data: (t) => IconButton(
                icon: const Icon(Icons.assignment_ind_outlined),
                tooltip: 'Assign Helpdesk',
                onPressed: () => _showAssignSheet(t),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          if (isStaff)
            ticketAsync.maybeWhen(
              data: (t) {
                final isHelpdesk = user?.role == UserRole.helpdesk;
                final isAssignedToMe = t.assignedToId == user?.id;
                // Helpdesk: tampilkan icon berbeda jika tiket bukan miliknya
                return IconButton(
                  icon: Icon(
                    Icons.edit_outlined,
                    color: (isHelpdesk && !isAssignedToMe)
                        ? Theme.of(context).disabledColor
                        : null,
                  ),
                  tooltip: (isHelpdesk && !isAssignedToMe)
                      ? 'Tiket ini tidak ditugaskan kepada Anda'
                      : 'Update Status',
                  onPressed: () => _showStatusSheet(t),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorView(
          message: e.toString().replaceAll('Exception: ', ''),
          onRetry: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
        ),
        data: (ticket) => Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(ticket),
                    const SizedBox(height: 16),
                    _buildMeta(ticket),
                    const Divider(height: 32),
                    _buildDescription(ticket),
                    if (ticket.attachments.isNotEmpty) ...[
                      const Divider(height: 32),
                      _buildAttachments(ticket.attachments),
                    ],
                    const Divider(height: 32),
                    _buildTimeline(ticket),
                    const Divider(height: 32),
                    _buildHistorySection(),
                    const Divider(height: 32),
                    _buildCommentSection(ticket, user?.id ?? ''),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildCommentInput(user),
          ],
        ),
      ),
    );
  }

  // ─── Sections ──────────────────────────────────────────────

  Widget _buildHeader(TicketModel ticket) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(status: ticket.status),
            const SizedBox(width: 8),
            PriorityBadge(priority: ticket.priority),
            const Spacer(),
            Text(
              relativeTime(ticket.createdAt),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(ticket.title, style: theme.textTheme.headlineSmall),
      ],
    );
  }

  Widget _buildMeta(TicketModel ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _metaRow(Icons.category_outlined, ticket.category),
        _metaRow(
          Icons.person_outline_rounded,
          'Dibuat oleh: ${ticket.createdByName ?? '-'}',
        ),
        if (ticket.assignedToName != null)
          _metaRow(
            Icons.assignment_ind_outlined,
            'Ditugaskan: ${ticket.assignedToName}',
          ),
      ],
    );
  }

  Widget _metaRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildDescription(TicketModel ticket) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Deskripsi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(ticket.description, style: theme.textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildAttachments(List<TicketAttachmentModel> attachments) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lampiran (${attachments.length})',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: attachments.map((a) => _attachChip(a)).toList(),
        ),
      ],
    );
  }

  Widget _attachChip(TicketAttachmentModel a) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          a.isImage ? Icons.image_outlined : Icons.attach_file_rounded,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          a.fileName,
          style: const TextStyle(fontSize: 12, color: AppColors.primary),
        ),
      ],
    ),
  );

  Widget _buildTimeline(TicketModel ticket) {
    final theme = Theme.of(context);
    final steps = [
      (label: 'Tiket Dibuat', done: true, date: ticket.createdAt),
      (
        label: 'Sedang Ditangani',
        done: ticket.status != TicketStatus.open,
        date: null,
      ),
      (
        label: 'Diselesaikan',
        done:
            ticket.status == TicketStatus.resolved ||
            ticket.status == TicketStatus.closed,
        date: ticket.resolvedAt,
      ),
      (
        label: 'Ditutup',
        done: ticket.status == TicketStatus.closed,
        date: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status Tracking', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...steps.asMap().entries.map((e) {
          final isLast = e.key == steps.length - 1;
          final step = e.value;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: step.done
                          ? AppColors.statusResolved
                          : theme.dividerColor,
                      shape: BoxShape.circle,
                    ),
                    child: step.done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: step.done
                          ? AppColors.statusResolved.withValues(alpha: 0.4)
                          : theme.dividerColor,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: step.done ? FontWeight.w600 : null,
                          color: step.done
                              ? null
                              : theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      if (step.date != null)
                        Text(
                          _fmtDate(step.date!),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildHistorySection() {
    final theme = Theme.of(context);
    final historyAsync = ref.watch(ticketHistoryProvider(widget.ticketId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Riwayat Aktivitas', style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            historyAsync.maybeWhen(
              data: (list) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${list.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Gagal memuat riwayat',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          data: (historyList) {
            if (historyList.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 40,
                        color: theme.dividerColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada riwayat',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: historyList
                  .asMap()
                  .entries
                  .map((e) => _buildHistoryEntry(
                        e.value,
                        isLast: e.key == historyList.length - 1,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryEntry(TicketHistoryModel entry, {bool isLast = false}) {
    final theme = Theme.of(context);

    final (icon, color) = switch (entry.action) {
      'created' => (Icons.add_circle_rounded, AppColors.statusResolved),
      'status_changed' => (Icons.sync_alt_rounded, AppColors.statusInProgress),
      'assigned' => (Icons.assignment_ind_rounded, AppColors.statusAssigned),
      'comment_added' => (Icons.chat_bubble_rounded, AppColors.accent),
      _ => (Icons.info_outline_rounded, AppColors.statusClosed),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: theme.dividerColor,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.performedByName} · ${_fmtDate(entry.createdAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentSection(TicketModel ticket, String myId) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Komentar', style: theme.textTheme.titleMedium),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${ticket.comments.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (ticket.comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 40,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(height: 8),
                  Text('Belum ada komentar', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          )
        else
          ...ticket.comments.map((c) => _buildCommentBubble(c, myId)),
      ],
    );
  }

  Widget _buildCommentBubble(TicketCommentModel comment, String myId) {
    final theme = Theme.of(context);
    final isMe = comment.authorId == myId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            AppAvatar(
              name: comment.authorName,
              avatarUrl: comment.authorAvatar,
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  children: [
                    Text(
                      isMe ? 'Anda' : comment.authorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _fmtDate(comment.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : theme.cardTheme.color,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                    border: Border.all(
                      color: isMe
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : theme.dividerColor,
                    ),
                  ),
                  child: Text(
                    comment.content,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            AppAvatar(
              name: comment.authorName,
              avatarUrl: comment.authorAvatar,
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentInput(UserModel? user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (user != null)
              AppAvatar(name: user.name, avatarUrl: user.avatarUrl, radius: 17),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Tulis komentar...',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: _sendComment,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    return DateFormat('dd MMM yyyy, HH:mm').format(d);
  }
}
