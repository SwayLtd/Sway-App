// event_artist_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/services/event_service.dart';

class EventArtistService {
  Future<List<Map<String, dynamic>>> getArtistsByEventId(String eventId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson =
        json.decode(response) as List<dynamic>;
    final artistEntries =
        eventArtistJson.where((entry) => entry['eventId'] == eventId).toList();

    final artists = await ArtistService().getArtists();
    final artistMap = {for (var artist in artists) artist.id: artist};

    return artistEntries.map((entry) {
      final artist = artistMap[entry['artistId']];
      return {
        'artist': artist,
        'startTime':
            (entry['startTime'] is String) ? entry['startTime'] as String : '',
        'endTime':
            (entry['endTime'] is String) ? entry['endTime'] as String : '',
        'status': (entry['status'] as String?) ?? '',
        'stage': (entry['stage'] as String?) ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getEventsByArtistId(
      String artistId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson =
        json.decode(response) as List<dynamic>;
    final eventEntries = eventArtistJson
        .where((entry) => entry['artistId'] == artistId)
        .toList();

    final events = await EventService().getEvents();
    final eventMap = {for (var event in events) event.id: event};

    return eventEntries.map((entry) {
      final event = eventMap[entry['eventId']];
      return {
        'event': event,
        'startTime':
            (entry['startTime'] is String) ? entry['startTime'] as String : '',
        'endTime':
            (entry['endTime'] is String) ? entry['endTime'] as String : '',
        'status': (entry['status'] as String?) ?? '',
        'stage': (entry['stage'] as String?) ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getArtistsByEventIdAndDay(
    String eventId,
    DateTime day,
  ) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);
    print('Total artists for event $eventId: ${artists.length}');

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

    final DateTime dayEnd = dayStart.add(Duration(days: 1));

    List<Map<String, dynamic>> filteredArtists = artists.where((entry) {
      final startTimeStr = entry['startTime'] as String?;
      final endTimeStr = entry['endTime'] as String?;
      if (startTimeStr != null && endTimeStr != null) {
        try {
          final startTime = DateTime.parse(startTimeStr);
          final endTime = DateTime.parse(endTimeStr);

          // Performance falls within the festival day window
          final isWithinDay =
              (startTime.isAfter(dayStart) && startTime.isBefore(dayEnd)) ||
                  (endTime.isAfter(dayStart) && endTime.isBefore(dayEnd)) ||
                  (startTime.isBefore(dayStart) && endTime.isAfter(dayStart));

          return isWithinDay;
        } catch (e) {
          print(
              'Invalid date format for artist: ${entry['artist'].name}, StartTime: $startTimeStr, EndTime: $endTimeStr');
        }
      }
      return false;
    }).toList();

    print('Loaded ${filteredArtists.length} artists for selected day: $day');
    return filteredArtists;
  }

  Future<DateTime> _getPreviousDayEndTime(String eventId, DateTime day) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);

    DateTime dayStart = DateTime(day.year, day.month, day.day, 6,
        0); // Default start time for days after the first day
    DateTime previousDayEndTime = dayStart;

    for (var entry in artists) {
      final startTimeStr = entry['startTime'] as String?;
      final endTimeStr = entry['endTime'] as String?;
      if (startTimeStr != null && endTimeStr != null) {
        try {
          final startTime = DateTime.parse(startTimeStr);
          final endTime = DateTime.parse(endTimeStr);

          if (endTime.isBefore(day) && endTime.isAfter(previousDayEndTime)) {
            previousDayEndTime = endTime;
          }
        } catch (e) {
          print(
              'Invalid date format for artist: ${entry['artist'].name}, StartTime: $startTimeStr, EndTime: $endTimeStr');
        }
      }
    }

    return previousDayEndTime;
  }
}
