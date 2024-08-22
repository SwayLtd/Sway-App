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
      eventId: json['eventId'],
      ticketType: json['ticketType'],
      price: json['price'],
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      waveEndDate: json['waveEndDate'] != null
          ? DateTime.parse(json['waveEndDate'])
          : null,
      maxPurchases: json['maxPurchases'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'ticketType': ticketType,
      'price': price,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'waveEndDate': waveEndDate?.toIso8601String(),
      'maxPurchases': maxPurchases,
    };
  }

  String generateQRCode(int userId, DateTime timestamp) {
    final data = '$id-$userId-${timestamp.toIso8601String()}';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
