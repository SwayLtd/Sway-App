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
      userId: json['user_id'] ?? 0,
      eventId: json['event_id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'ticket_id': ticketId,
      'status': status,
    };
  }
}
