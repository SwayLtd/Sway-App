class UserInterestEvent {
  final int userId;
  final int eventId;
  final String status; // "interested" or "going"

  UserInterestEvent({
    required this.userId,
    required this.eventId,
    required this.status,
  });

  factory UserInterestEvent.fromJson(Map<String, dynamic> json) {
    return UserInterestEvent(
      userId: json['userId'],
      eventId: json['eventId'],
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status,
    };
  }
}
