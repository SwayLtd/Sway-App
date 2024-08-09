// timetable_utils.dart

import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';

Future<List<DateTime>> calculateFestivalDays(Event event) async {
  final List<Map<String, dynamic>> artists =
      await EventArtistService().getArtistsByEventId(event.id);

  final Set<DateTime> daysWithArtists = {};
  final Map<DateTime, List<Map<String, dynamic>>> artistsByDay = {};

  for (final entry in artists) {
    final startTime = DateTime.parse(entry['startTime'] as String);
    final endTime = DateTime.parse(entry['endTime'] as String);

    final startDay = DateTime(startTime.year, startTime.month, startTime.day);
    final endDay = DateTime(endTime.year, endTime.month, endTime.day);

    artistsByDay.putIfAbsent(startDay, () => []).add(entry);
    if (endDay != startDay) {
      artistsByDay.putIfAbsent(endDay, () => []).add(entry);
    }
  }

  for (final day in artistsByDay.keys.toList()..sort()) {
    final dayArtists = artistsByDay[day]!;
    dayArtists.sort((a, b) {
      return DateTime.parse(a['startTime'] as String)
          .compareTo(DateTime.parse(b['startTime'] as String));
    });

    bool isContinuation = false;

    for (int i = 0; i < dayArtists.length; i++) {
      final artistStartTime =
          DateTime.parse(dayArtists[i]['startTime'] as String);

      if (artistStartTime.hour < 5) {
        if (i > 0) {
          final previousArtistEndTime =
              DateTime.parse(dayArtists[i - 1]['endTime'] as String);

          if (artistStartTime.difference(previousArtistEndTime).inMinutes <=
              60) {
            isContinuation = true;
          } else {
            isContinuation = false;
            break;
          }
        } else {
          final previousDay = day.subtract(const Duration(days: 1));
          final previousDayArtists = artistsByDay[previousDay];
          if (previousDayArtists != null && previousDayArtists.isNotEmpty) {
            final lastArtistPreviousDayEndTime =
                DateTime.parse(previousDayArtists.last['endTime'] as String);

            if (artistStartTime
                    .difference(lastArtistPreviousDayEndTime)
                    .inMinutes <=
                60) {
              isContinuation = true;
            }
          }
        }
      } else {
        // Si un artiste commence après 5h du matin, ce jour est valide
        isContinuation = false;
        break;
      }
    }

    // Ne pas ajouter le jour s'il n'a que des événements qui sont une continuation de la veille
    if (!isContinuation || artistsByDay[day]!.any((artist) {
      final artistStartTime = DateTime.parse(artist['startTime'] as String);
      return artistStartTime.hour >= 5;
    })) {
      daysWithArtists.add(day);
    }
  }

  return daysWithArtists.toList()..sort();
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
          const Center(
            child: Text(
              'ARTISTS',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
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
          }),
        ],
      );
    },
  );
}
