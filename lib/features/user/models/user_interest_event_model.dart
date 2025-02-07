// lib/features/user/models/user_interest_event_model.dart

class UserInterestEvent {
  final int id;
  final int userId;
  final int eventId;
  final String status; // "interested", "going" or "not_interested"

  UserInterestEvent({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
  });

  factory UserInterestEvent.fromJson(Map<String, dynamic> json) {
    return UserInterestEvent(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      eventId: json['event_id'] as int,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'status': status,
    };
  }
}
