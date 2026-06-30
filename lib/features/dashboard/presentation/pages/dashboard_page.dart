import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';

import 'package:eticketing_helpdesk/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/create_ticket_page.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/widgets/ticket_card_widget.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authProvider).value;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentAsync = ref.watch(recentTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Halo, ${user?.name.split(' ').first ?? '...'} 👋',
              style: theme.textTheme.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              user?.role.label ?? '',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(recentTicketsProvider);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_dashboard',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTicketPage()),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat Tiket'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentTicketsProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Banner ─────────────────────────────────
                  statsAsync.when(
                    loading: () => _shimmerBox(height: 110),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (s) => _buildBanner(s.open, s.total),
                  ),
                  const SizedBox(height: 24),

                  // ── Stats Grid ──────────────────────────────
                  const SectionHeader(title: 'Statistik Tiket'),
                  const SizedBox(height: 12),

                  statsAsync.when(
                    loading: () => _buildStatsGrid(isLoading: true),
                    error: (e, _) => AppErrorView(
                      message: e.toString().replaceAll('Exception: ', ''),
                    ),
                    data: (s) => _buildStatsGrid(stats: s),
                  ),
                  const SizedBox(height: 24),

                  // ── Recent Tickets ──────────────────────────
                  SectionHeader(
                    title: 'Tiket Terbaru',
                    trailing: TextButton(
                      onPressed: () {},
                      child: const Text('Lihat Semua'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  recentAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => AppErrorView(
                      message: e.toString().replaceAll('Exception: ', ''),
                      onRetry: () => ref.invalidate(recentTicketsProvider),
                    ),
                    data: (tickets) => tickets.isEmpty
                        ? const AppEmptyState(
                            title: 'Belum ada tiket',
                            subtitle:
                                'Tap tombol + untuk membuat tiket pertama',
                            icon: Icons.confirmation_number_outlined,
                          )
                        : Column(
                            children: tickets
                                .map(
                                  (t) => TicketCardWidget(
                                    ticket: t,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            TicketDetailPage(ticketId: t.id),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Banner ────────────────────────────────────────────────
  Widget _buildBanner(int open, int total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tiket Aktif',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$open Perlu Perhatian',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Total $total tiket terdaftar',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Grid ───────────────────────────────
  Widget _buildStatsGrid({bool isLoading = false, dynamic stats}) {
    if (isLoading) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 20) / 3;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(
              5,
              (_) => SizedBox(
                width: cardWidth,
                height: cardWidth * 1.1,
                child: _shimmerBox(),
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 20) / 3;
        final cardHeight = cardWidth * 1.1;

        final items = <_StatsItem>[
          _StatsItem('Total', stats.total, AppColors.primary,
              Icons.confirmation_number_rounded),
          _StatsItem(
              'Open', stats.open, AppColors.statusOpen,
              Icons.radio_button_unchecked_rounded),
          _StatsItem('Assigned', stats.assigned, AppColors.statusAssigned,
              Icons.assignment_ind_rounded),
          _StatsItem('In Progress', stats.inProgress,
              AppColors.statusInProgress, Icons.pending_rounded),
          _StatsItem('Closed', stats.closed, AppColors.statusClosed,
              Icons.task_alt_rounded),
        ];

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: StatsCard(
                    label: item.label,
                    count: item.count,
                    color: item.color,
                    icon: item.icon,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ─── Shimmer placeholder ───────────────────────────────────
  Widget _shimmerBox({double? height}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
    ),
  );
}

// ─── Helper class for stats items ─────────────────────────────
class _StatsItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatsItem(this.label, this.count, this.color, this.icon);
}
