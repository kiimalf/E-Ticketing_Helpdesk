import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/widgets/app_widgets.dart';
import 'package:eticketing_helpdesk/features/user/presentation/providers/user_provider.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:eticketing_helpdesk/features/user/presentation/pages/user_form_page.dart';

class UserListPage extends ConsumerStatefulWidget {
  const UserListPage({super.key});

  @override
  ConsumerState<UserListPage> createState() => _UserListPageState();
}

// ignore_for_file: use_build_context_synchronously
class _UserListPageState extends ConsumerState<UserListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(userSearchQueryProvider.notifier).setQuery(value);
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    UserModel user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna "${user.name}" secara permanen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(userManagementProvider.notifier).deleteUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsersAsync = ref.watch(filteredUserListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pengguna'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama atau email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
      body: filteredUsersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorView(
          message: error.toString(),
          onRetry: () => ref.read(userManagementProvider.notifier).refresh(),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Tidak ada pengguna ditemukan.'));
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(userManagementProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final roleColor = _getRoleColor(user.role);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.2),
                      foregroundColor: roleColor,
                      child: Text(user.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(
                      user.name,
                      style: TextStyle(
                        decoration: user.isActive
                            ? null
                            : TextDecoration.lineThrough,
                        color: user.isActive ? null : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: roleColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                user.role.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: roleColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: user.isActive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: user.isActive
                                      ? Colors.green.withValues(alpha: 0.5)
                                      : Colors.red.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                user.isActive ? 'Aktif' : 'Non-aktif',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.isActive
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserFormPage(user: user),
                            ),
                          );
                        } else if (value == 'toggle_status') {
                          ref
                              .read(userManagementProvider.notifier)
                              .toggleUserActiveStatus(user.id, user.isActive);
                        } else if (value == 'delete') {
                          _showDeleteConfirmDialog(context, user);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle_status',
                          child: Row(
                            children: [
                              Icon(
                                user.isActive
                                    ? Icons.block
                                    : Icons.check_circle,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(user.isActive ? 'Non-aktifkan' : 'Aktifkan'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_users',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserFormPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.purple;
      case UserRole.helpdesk:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }
}
