// event_artist_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/services/event_service.dart';

class EventArtistService {
  Future<List<Map<String, dynamic>>> getArtistsByEventId(int eventId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson =
        json.decode(response) as List<dynamic>;
    final artistEntries =
        eventArtistJson.where((entry) => entry['event_id'] == eventId).toList();

    final artists = await ArtistService().getArtists();
    final artistMap = {for (final artist in artists) artist.id: artist};

    return artistEntries.map((entry) {
      final artistIds = (entry['artist_id'] as List<dynamic>)
          .map((id) => artistMap[id])
          .toList();
      final validArtists = artistIds.where((artist) => artist != null).toList();
      return {
        'artists': validArtists,
        'custom_name': entry['custom_name'] as String?,
        'start_time':
            DateTime.parse(entry['start_time']),
        'end_time':
            DateTime.parse(entry['end_time']),
        'status': (entry['status'] as String?) ?? '',
        'stage': (entry['stage'] as String?) ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getEventsByArtistId(
    int artistId,
  ) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson =
        json.decode(response) as List<dynamic>;
    final eventEntries = eventArtistJson
        .where(
          (entry) => (entry['artist_id'] as List<dynamic>).contains(artistId),
        )
        .toList();

    final events = await EventService().getEvents();
    final eventMap = {for (final event in events) event.id: event};

    return eventEntries.map((entry) {
      final event = eventMap[entry['event_id']];
      return {
        'event': event,
        'start_time':
            entry['start_time'],
        'end_time':
            entry['end_time'],
        'status': (entry['status'] as String?) ?? '',
        'stage': (entry['stage'] as String?) ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getArtistsByEventIdAndDay(
    int eventId,
    DateTime day,
  ) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);

    // Obtenir l'heure de début du festival
    final DateTime? festivalStartTime =
        await EventService().getFestivalStartTime(eventId);

    // Définir l'heure de début du jour de festival en fonction du jour précédent
    DateTime dayStart;
    if (day.isAtSameMomentAs(festivalStartTime!)) {
      dayStart = festivalStartTime;
    } else {
      dayStart = await _getPreviousDayEndTime(eventId, day);
    }

    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final List<Map<String, dynamic>> filteredArtists = artists.where((entry) {
      final startTimeStr = entry['start_time'] as String?;
      final endTimeStr = entry['end_time'] as String?;
      if (startTimeStr != null && endTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr);
        final endTime = DateTime.parse(endTimeStr);

        // Performance falls within the festival day window
        final isWithinDay =
            (startTime.isAfter(dayStart) && startTime.isBefore(dayEnd)) ||
                (endTime.isAfter(dayStart) && endTime.isBefore(dayEnd)) ||
                (startTime.isBefore(dayStart) && endTime.isAfter(dayStart));

        return isWithinDay;
      }
      return false;
    }).toList();

    return filteredArtists;
  }

  Future<DateTime> _getPreviousDayEndTime(int eventId, DateTime day) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);

    final DateTime dayStart = DateTime(
      day.year,
      day.month,
      day.day,
      6,
    ); // Default start time for days after the first day
    DateTime previousDayEndTime = dayStart;

    for (final entry in artists) {
      final startTimeStr = entry['start_time'] as String?;
      final endTimeStr = entry['end_time'] as String?;
      if (startTimeStr != null && endTimeStr != null) {
        DateTime.parse(startTimeStr);
        final endTime = DateTime.parse(endTimeStr);

        if (endTime.isBefore(day) && endTime.isAfter(previousDayEndTime)) {
          previousDayEndTime = endTime;
        }
      }
    }

    return previousDayEndTime;
  }
}