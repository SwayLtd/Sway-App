import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
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


void showArtistsBottomSheet(BuildContext context, List<Artist> artists) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(),
    builder: (BuildContext context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 50,
            margin: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          ...artists.map((artist) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: ImageWithErrorHandler(
                  imageUrl: artist.imageUrl,
                  width: 40,
                  height: 40,
                ),
              ),
              title: Text(artist.name),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArtistScreen(artistId: artist.id),
                  ),
                );
              },
            );
          }).toList(),
        ],
      );
    },
  );
}
