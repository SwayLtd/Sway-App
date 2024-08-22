// user_event_ticket_model.dart


class UserEventTicket {
  final int id;
  final int userId;
  final int eventId;
  final int ticketId;
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
      id: json['id'],
      userId: json['userId'] ?? 0,
      eventId: json['eventId'] ?? 0,
      ticketId: json['ticketId'] ?? 0,
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
