// lib/features/ticketing/models/online_ticket_model.dart
import 'dart:convert';

/// OnlineTicket model used for online tickets.
class OnlineTicket {
  /// Unique ticket identifier (UUID)
  final String id;

  /// Path to the QR code image stored in Supabase Storage (bucket "tickets")
  final String qrCodePath;

  /// Indicates whether the ticket has been used.
  final bool used;

  /// Timestamp when the ticket was marked as used.
  final DateTime? usedAt;

  /// Timestamp when the ticket was created.
  final DateTime createdAt;

  /// Associated event ID (int).
  final int eventId;

  /// Optional ticket type (e.g., "VIP", "General Admission").
  final String? ticketType;

  /// Optional group ID if applicable.
  final String? groupId;

  OnlineTicket({
    required this.id,
    required this.qrCodePath,
    required this.used,
    this.usedAt,
    required this.createdAt,
    required this.eventId,
    this.ticketType,
    this.groupId,
  });

  /// Converts OnlineTicket instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'qr_code_path': qrCodePath,
      'used': used,
      'used_at': usedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'event_id': eventId,
      'ticket_type': ticketType,
      'group_id': groupId,
    };
  }

  /// Creates an OnlineTicket instance from a Map.
  factory OnlineTicket.fromMap(Map<String, dynamic> map) {
    return OnlineTicket(
      id: map['id'] as String,
      qrCodePath: map['qr_code_path'] as String,
      used: map['used'] as bool,
      usedAt: map['used_at'] != null ? DateTime.parse(map['used_at']) : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      eventId: map['event_id'] as int,
      ticketType: map['ticket_type'] as String?,
      groupId: map['group_id'] as String?,
    );
  }

  /// Converts the OnlineTicket instance to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates an OnlineTicket instance from a JSON string.
  factory OnlineTicket.fromJson(String source) =>
      OnlineTicket.fromMap(json.decode(source));
}
