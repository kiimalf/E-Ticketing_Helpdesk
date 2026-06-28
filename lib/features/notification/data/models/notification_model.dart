import 'package:eticketing_helpdesk/core/constants/app_constants.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String? ticketId;
  final bool isRead;
  final NotificationType type;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.ticketId,
    this.isRead = false,
    required this.type,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      ticketId: map['ticket_id'] as String?,
      isRead: (map['is_read'] as bool?) ?? false,
      type: NotificationTypeX.fromString(map['type'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
    id: id,
    userId: userId,
    title: title,
    body: body,
    ticketId: ticketId,
    isRead: isRead ?? this.isRead,
    type: type,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is NotificationModel && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
