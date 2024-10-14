import 'dart:convert';

import 'package:crypto/crypto.dart';

class Ticket {
  final int id;
  final int eventId;
  final String ticketType;
  final String price;
  final String status;
  final DateTime createdAt;
  final DateTime? waveEndDate;
  final int? maxPurchases;

  Ticket({
    required this.id,
    required this.eventId,
    required this.ticketType,
    required this.price,
    required this.status,
    required this.createdAt,
    this.waveEndDate,
    this.maxPurchases,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      eventId: json['event_id'],
      ticketType: json['ticket_type'],
      price: json['price'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      waveEndDate: json['wave_end_date'] != null
          ? DateTime.parse(json['wave_end_date'])
          : null,
      maxPurchases: json['max_purchases'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event_id': eventId,
      'ticket_type': ticketType,
      'price': price,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'wave_end_date': waveEndDate?.toIso8601String(),
      'max_purchases': maxPurchases,
    };
  }

  String generateQRCode(int userId, DateTime timestamp) {
    final data = '$id-$userId-${timestamp.toIso8601String()}';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
