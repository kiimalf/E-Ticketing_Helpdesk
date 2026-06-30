import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/theme/app_theme.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/widgets/ticket_card_widget.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/ticket_detail_page.dart';
import 'package:eticketing_helpdesk/features/ticket/presentation/pages/create_ticket_page.dart';
import 'package:eticketing_helpdesk/features/user/presentation/providers/user_provider.dart';
import 'package:eticketing_helpdesk/features/auth/presentation/providers/auth_provider.dart';

class TicketListPage extends ConsumerStatefulWidget {
  const TicketListPage({super.key});

  @override
  ConsumerState<TicketListPage> createState() => _TicketListPageState();
}

class _TicketListPageState extends ConsumerState<TicketListPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final current = ref.read(ticketFilterProvider);
    TicketStatus? tempStatus = current.status;
    TicketPriority? tempPriority = current.priority;
    String? tempAssignedTo = current.assignedToId;

    final authState = ref.read(authProvider);
    final isAdmin = authState.value?.role == UserRole.admin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Filter Tiket',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      ref.read(ticketFilterProvider.notifier).clear();
                      _searchCtrl.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Status', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TicketStatus.values
                    .map(
                      (s) => FilterChip(
                        label: Text(s.label),
                        selected: tempStatus == s,
                        onSelected: (v) =>
                            setModal(() => tempStatus = v ? s : null),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Prioritas', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TicketPriority.values
                    .map(
                      (p) => FilterChip(
                        label: Text(p.label),
                        selected: tempPriority == p,
                        onSelected: (v) =>
                            setModal(() => tempPriority = v ? p : null),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              if (isAdmin) ...[
                Text(
                  'Ditugaskan Kepada',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Consumer(
                  builder: (context, ref, _) {
                    final usersAsync = ref.watch(userManagementProvider);
                    return usersAsync.maybeWhen(
                      data: (users) {
                        final helpdesks = users
                            .where((u) => u.role == UserRole.helpdesk)
                            .toList();
                        return DropdownButtonFormField<String?>(
                          initialValue: tempAssignedTo,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Semua'),
                            ),
                            ...helpdesks.map(
                              (h) => DropdownMenuItem(
                                value: h.id,
                                child: Text(h.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => setModal(() => tempAssignedTo = v),
                        );
                      },
                      orElse: () => const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
              ElevatedButton(
                onPressed: () {
                  ref.read(ticketFilterProvider.notifier)
                    ..setStatus(tempStatus)
                    ..setPriority(tempPriority)
                    ..setAssignedTo(tempAssignedTo);
                  Navigator.pop(ctx);
                },
                child: const Text('Terapkan Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketListProvider);
    final filter = ref.watch(ticketFilterProvider);
    final authState = ref.watch(authProvider);
    final isHelpdesk = authState.value?.role == UserRole.helpdesk;
    final helpdeskOnlyAssigned = ref.watch(helpdeskAssignedFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: filter.hasFilter,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_tickets',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTicketPage()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari tiket...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: filter.search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(ticketFilterProvider.notifier).setSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: (q) =>
                  ref.read(ticketFilterProvider.notifier).setSearch(q),
            ),
          ),

          // Helpdesk: toggle Tiket Saya vs Semua Tiket
          if (isHelpdesk)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('Tiket Saya'),
                      icon: Icon(Icons.assignment_ind_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('Semua Tiket'),
                      icon: Icon(Icons.list_alt_rounded, size: 18),
                    ),
                  ],
                  selected: {helpdeskOnlyAssigned},
                  onSelectionChanged: (v) =>
                      ref.read(helpdeskAssignedFilterProvider.notifier).updateState(
                          v.first),
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),

          // Active filter chips
          if (filter.hasFilter)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.filter_alt_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  if (filter.status != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text(
                          filter.status!.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onDeleted: () => ref
                            .read(ticketFilterProvider.notifier)
                            .setStatus(null),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  if (filter.priority != null)
                    Chip(
                      label: Text(
                        filter.priority!.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onDeleted: () => ref
                          .read(ticketFilterProvider.notifier)
                          .setPriority(null),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),

          // List
          Expanded(
            child: ticketsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AppErrorView(
                message: e.toString().replaceAll('Exception: ', ''),
                onRetry: () => ref.invalidate(ticketListProvider),
              ),
              data: (tickets) => tickets.isEmpty
                  ? AppEmptyState(
                      title: filter.hasFilter
                          ? 'Tidak ada hasil'
                          : 'Belum ada tiket',
                      subtitle: filter.hasFilter
                          ? 'Coba ubah filter pencarian'
                          : 'Tap + untuk membuat tiket baru',
                      icon: Icons.inbox_outlined,
                      action: filter.hasFilter
                          ? OutlinedButton(
                              onPressed: () {
                                ref.read(ticketFilterProvider.notifier).clear();
                                _searchCtrl.clear();
                              },
                              child: const Text('Hapus Filter'),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(ticketListProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tickets.length,
                        itemBuilder: (_, i) => TicketCardWidget(
                          ticket: tickets[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TicketDetailPage(ticketId: tickets[i].id),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
