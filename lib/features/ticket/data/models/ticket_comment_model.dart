import 'package:eticketing_helpdesk/core/constants/app_constants.dart';

class TicketCommentModel {
  final String id;
  final String ticketId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final UserRole authorRole;
  final String content;
  final bool isInternal;
  final DateTime createdAt;

  const TicketCommentModel({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.authorRole,
    required this.content,
    this.isInternal = false,
    required this.createdAt,
  });

  factory TicketCommentModel.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return TicketCommentModel(
      id: map['id'] as String,
      ticketId: map['ticket_id'] as String,
      authorId: map['author_id'] as String,
      authorName: (profile?['name'] as String?) ?? 'Unknown',
      authorAvatar: profile?['avatar_url'] as String?,
      authorRole: UserRoleX.fromString(profile?['role'] as String?),
      content: map['content'] as String,
      isInternal: (map['is_internal'] as bool?) ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Payload untuk INSERT ke Supabase
  Map<String, dynamic> toInsertMap() => {
    'ticket_id': ticketId,
    'author_id': authorId,
    'content': content,
    'is_internal': isInternal,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TicketCommentModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
