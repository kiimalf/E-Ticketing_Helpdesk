import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';
import 'package:eticketing_helpdesk/features/user/data/repositories/user_repository.dart';

final userSearchQueryProvider =
    NotifierProvider<UserSearchQueryNotifier, String>(
      UserSearchQueryNotifier.new,
    );

class UserSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
}

class UserManagementNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final repository = ref.watch(userRepositoryProvider);
    return repository.fetchAllUsers();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  // createUser method dihapus

  Future<void> updateUser({
    required String id,
    String? name,
    UserRole? role,
    String? department,
  }) async {
    final repository = ref.read(userRepositoryProvider);
    await repository.updateUser(
      id: id,
      name: name,
      role: role,
      department: department,
    );
    await refresh();
  }

  Future<void> deleteUser(String id) async {
    final repository = ref.read(userRepositoryProvider);
    await repository.deleteUser(id);
    await refresh();
  }

  Future<void> toggleUserActiveStatus(String id, bool currentStatus) async {
    final repository = ref.read(userRepositoryProvider);
    await repository.deactivateUser(id, !currentStatus);
    await refresh();
  }
}

final userManagementProvider =
    AsyncNotifierProvider<UserManagementNotifier, List<UserModel>>(
      UserManagementNotifier.new,
    );

// Provider untuk mendapatkan user list yang sudah difilter
final filteredUserListProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersState = ref.watch(userManagementProvider);
  final searchQuery = ref.watch(userSearchQueryProvider).toLowerCase();

  return usersState.whenData((users) {
    if (searchQuery.isEmpty) return users;

    return users.where((user) {
      final matchName = user.name.toLowerCase().contains(searchQuery);
      final matchEmail = user.email.toLowerCase().contains(searchQuery);
      return matchName || matchEmail;
    }).toList();
  });
});
