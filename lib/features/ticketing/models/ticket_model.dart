// lib/features/ticketing/models/ticket_model.dart

import 'dart:convert';

class Ticket {
  int id;
  String filePath;
  DateTime importedDate;
  int? eventId;
  String? eventName;
  DateTime? eventDate;
  String? eventLocation;
  String? ticketType;

  Ticket({
    required this.id,
    required this.filePath,
    required this.importedDate,
    this.eventId,
    this.eventName,
    this.eventDate,
    this.eventLocation,
    this.ticketType,
  });

  // Conversion de l'objet Ticket en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filePath': filePath,
      'importedDate': importedDate.toIso8601String(),
      'eventId': eventId,
      'eventName': eventName,
      'eventDate': eventDate?.toIso8601String(),
      'eventLocation': eventLocation,
      'ticketType': ticketType,
    };
  }

  // Création d'un objet Ticket à partir d'un Map
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'],
      filePath: map['filePath'],
      importedDate: DateTime.parse(map['importedDate']),
      eventId: map['eventId'],
      eventName: map['eventName'],
      eventDate: map['eventDate'] != null ? DateTime.parse(map['eventDate']) : null,
      eventLocation: map['eventLocation'],
      ticketType: map['ticketType'],
    );
  }

  // Conversion de l'objet Ticket en JSON
  String toJson() => json.encode(toMap());

  // Création d'un objet Ticket à partir d'un JSON
  factory Ticket.fromJson(String source) => Ticket.fromMap(json.decode(source));
}
