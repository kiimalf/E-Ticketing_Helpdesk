// ignore_for_file: use_null_aware_elements
import 'package:eticketing_helpdesk/core/constants/app_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final UserRole role;
  final String? department;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.role,
    this.department,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // ─── Factory: dari Map Supabase ───────────────────────────
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? 'Unknown',
      email: (map['email'] as String?) ?? '',
      avatarUrl: map['avatar_url'] as String?,
      role: UserRoleX.fromString(map['role'] as String?),
      department: map['department'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(
        (map['updated_at'] as String?) ?? map['created_at'] as String,
      ),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  // ─── toMap untuk update profil ────────────────────────────
  Map<String, dynamic> toUpdateMap({
    String? name,
    String? avatarUrl,
    String? department,
  }) => {
    if (name != null) 'name': name,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (department != null) 'department': department,
    'updated_at': DateTime.now().toIso8601String(),
  };

  // ─── copyWith ─────────────────────────────────────────────
  UserModel copyWith({
    String? name,
    String? avatarUrl,
    UserRole? role,
    String? department,
    bool? isActive,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    role: role ?? this.role,
    department: department ?? this.department,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    isActive: isActive ?? this.isActive,
  );

  @override
  String toString() =>
      'UserModel(id: $id, name: $name, email: $email, role: ${role.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
