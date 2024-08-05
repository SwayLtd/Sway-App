import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';

Future<List<DateTime>> calculateFestivalDays(Event event) async {
  final List<Map<String, dynamic>> artists =
      await EventArtistService().getArtistsByEventId(event.id);

  DateTime? firstArtistStart;
  DateTime? lastArtistEnd;

  for (final entry in artists) {
    final startTimeStr = entry['startTime'] as String?;
    final endTimeStr = entry['endTime'] as String?;
    if (startTimeStr != null && endTimeStr != null) {
      final startTime = DateTime.parse(startTimeStr);
      final endTime = DateTime.parse(endTimeStr);
      if (firstArtistStart == null || startTime.isBefore(firstArtistStart)) {
        firstArtistStart = startTime;
      }
      if (lastArtistEnd == null || endTime.isAfter(lastArtistEnd)) {
        lastArtistEnd = endTime;
      }
    }
  }

  if (firstArtistStart == null || lastArtistEnd == null) {
    // Return the event dates as fallback
    firstArtistStart = DateTime.parse(event.dateTime);
    lastArtistEnd = DateTime.parse(event.endDateTime);
  }

  final List<DateTime> days = [];

  DateTime currentDay = DateTime(
    firstArtistStart.year,
    firstArtistStart.month,
    firstArtistStart.day,
  );
  while (currentDay.isBefore(lastArtistEnd) ||
      currentDay.isAtSameMomentAs(lastArtistEnd)) {
    days.add(currentDay);
    currentDay = currentDay.add(const Duration(days: 1));
  }

  return days;
}

String formatTime(String dateTime) {
  final time = DateTime.parse(dateTime);
  final formattedTime =
      "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  return formattedTime;
}
