import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eticketing_helpdesk/core/constants/app_constants.dart';
import 'package:eticketing_helpdesk/core/services/supabase_service.dart';
import 'package:eticketing_helpdesk/features/auth/data/models/user_model.dart';

class UserRepository {
  // ─── Fetch All Users ──────────────────────────────────────
  Future<List<UserModel>> fetchAllUsers() async {
    final data = await SupabaseService.from(
      SupabaseTables.profiles,
    ).select().order('created_at', ascending: false);

    return (data as List)
        .map((m) => UserModel.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // ─── Create User via REST API (auth.users) ─────────
  Future<UserModel> createUser({
    required String name,
    required String email,
    required UserRole role,
    String? department,
  }) async {
    throw UnimplementedError(
      'Fungsi Create User dari Admin dinonaktifkan demi keamanan. '
      'Silakan minta pengguna mendaftar melalui halaman Register biasa.',
    );
  }

  // ─── Update User ──────────────────────────────────────────
  Future<UserModel> updateUser({
    required String id,
    String? name,
    UserRole? role,
    String? department,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (role != null) updates['role'] = role.name;
    if (department != null) updates['department'] = department;

    final result = await SupabaseService.from(
      SupabaseTables.profiles,
    ).update(updates).eq('id', id).select().single();

    return UserModel.fromMap(result);
  }

  // ─── Delete User ──────────────────────────────────────────
  Future<void> deleteUser(String id) async {
    await SupabaseService.from(SupabaseTables.profiles).delete().eq('id', id);
  }

  // ─── Deactivate User ──────────────────────────────────────
  Future<void> deactivateUser(String id, bool isActive) async {
    await SupabaseService.from(SupabaseTables.profiles)
        .update({
          'is_active': isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', id);
  }
}

// ─── Riverpod Provider ────────────────────────────────────────
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});
