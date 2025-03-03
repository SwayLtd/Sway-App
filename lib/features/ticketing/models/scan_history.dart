// lib/features/ticketing/models/scan_history.dart
import 'dart:convert';

/// Model representing a scan log entry.
class ScanHistory {
  final String ticketId;
  final int eventId;
  final DateTime scannedAt;

  ScanHistory({
    required this.ticketId,
    required this.eventId,
    required this.scannedAt,
  });

  /// Converts ScanHistory instance to a Map.
  Map<String, dynamic> toMap() {
    return {
      'ticketId': ticketId,
      'eventId': eventId,
      'scannedAt': scannedAt.toIso8601String(),
    };
  }

  /// Creates a ScanHistory instance from a Map.
  factory ScanHistory.fromMap(Map<String, dynamic> map) {
    return ScanHistory(
      ticketId: map['ticketId'] as String,
      eventId: map['eventId'] as int,
      scannedAt: DateTime.parse(map['scannedAt'] as String),
    );
  }

  /// Converts the ScanHistory instance to a JSON string.
  String toJson() => json.encode(toMap());

  /// Creates a ScanHistory instance from a JSON string.
  factory ScanHistory.fromJson(String source) =>
      ScanHistory.fromMap(json.decode(source));
}
