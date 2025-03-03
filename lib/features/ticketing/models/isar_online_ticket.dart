// lib/features/ticketing/models/isar_online_ticket.dart

import 'dart:convert';
import 'package:isar/isar.dart';

part 'isar_online_ticket.g.dart';

/// Represents an online ticket stored in Isar.
@Collection()
class OnlineTicketIsar {
  /// Auto-incremented primary key for Isar.
  Id isarId = Isar.autoIncrement;

  /// Unique ticket identifier (UUID) from the online system.
  @Index(unique: true)
  late String id;

  /// Path to the QR code image stored in Supabase Storage (bucket "tickets").
  late String qrCodePath;

  /// Indicates whether the ticket has been used (scanned).
  late bool used;

  /// The timestamp when the ticket was marked as used, if applicable.
  DateTime? usedAt;

  /// The timestamp when the ticket was created.
  late DateTime createdAt;

  /// Associated event ID (int).
  late int eventId;

  /// Optional ticket type description (e.g., "VIP", "General Admission").
  String? ticketType;

  /// Optional group ID if the ticket belongs to a grouped purchase.
  String? groupId;

  OnlineTicketIsar({
    required this.id,
    required this.qrCodePath,
    required this.used,
    this.usedAt,
    required this.createdAt,
    required this.eventId,
    this.ticketType,
    this.groupId,
  });

  /// Converts the OnlineTicketIsar instance to a Map.
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

  /// Creates an OnlineTicketIsar instance from a Map.
  factory OnlineTicketIsar.fromMap(Map<String, dynamic> map) {
    return OnlineTicketIsar(
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

  /// Converts the OnlineTicketIsar instance to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates an OnlineTicketIsar instance from a JSON string.
  factory OnlineTicketIsar.fromJson(String source) =>
      OnlineTicketIsar.fromMap(json.decode(source));
}
