// user_event_ticket_model.dart


class UserEventTicket {
  final String id;
  final String userId;
  final String eventId;
  final String ticketId;
  final String status;

  UserEventTicket({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.ticketId,
    required this.status,
  });

  factory UserEventTicket.fromJson(Map<String, dynamic> json) {
    return UserEventTicket(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      ticketId: json['ticketId'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventId': eventId,
      'ticketId': ticketId,
      'status': status,
    };
  }
}
