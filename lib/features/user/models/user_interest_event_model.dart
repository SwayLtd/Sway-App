class UserInterestEvent {
  final String userId;
  final String eventId;
  final String status; // "interested" or "going"

  UserInterestEvent({
    required this.userId,
    required this.eventId,
    required this.status,
  });

  factory UserInterestEvent.fromJson(Map<String, dynamic> json) {
    return UserInterestEvent(
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
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
