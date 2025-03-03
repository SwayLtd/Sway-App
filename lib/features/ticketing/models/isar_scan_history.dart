// lib/features/ticketing/models/isar_scan_history.dart

import 'dart:convert';
import 'package:isar/isar.dart';

part 'isar_scan_history.g.dart';

/// Represents a scan log entry stored in Isar.
@Collection()
class IsarScanHistory {
  /// Auto-incremented primary key.
  Id id = Isar.autoIncrement;

  /// Ticket identifier that was scanned.
  late String ticketId;

  /// Associated event ID (int).
  late int eventId;

  /// Timestamp when the scan occurred.
  late DateTime scannedAt;

  IsarScanHistory({
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
  });

  /// Converts the IsarScanHistory instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  /// Creates an IsarScanHistory instance from a Map.
  factory IsarScanHistory.fromMap(Map<String, dynamic> map) {
    return IsarScanHistory(
      ticketId: map['ticketId'] as String,
      eventId: map['eventId'] as int,
      scannedAt: DateTime.parse(map['scannedAt'] as String),
    );
  }

  /// Converts the IsarScanHistory instance to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates an IsarScanHistory instance from a JSON string.
  factory IsarScanHistory.fromJson(String source) =>
      IsarScanHistory.fromMap(json.decode(source));
}
