// lib/features/notification/models/notification_model.dart

class NotificationModel {
  final String id;
  final String userSupabaseId;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final bool isSent;
  final Map<String, dynamic>? action; // New field for actions

  NotificationModel({
    required this.id,
    required this.userSupabaseId,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.scheduledTime,
    required this.isSent,
    this.action,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String,
      userSupabaseId: map['supabase_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      scheduledTime: map['scheduled_time'] != null
          ? DateTime.parse(map['scheduled_time'] as String)
          : null,
      isSent: map['is_sent'] as bool? ?? false,
      action: map['action'] != null
          ? Map<String, dynamic>.from(map['action'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supabase_id': userSupabaseId,
      'title': title,
      'body': body,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'is_sent': isSent,
      'action': action,
    };
  }
}
