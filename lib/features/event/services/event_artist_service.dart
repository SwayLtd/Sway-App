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
        'startTime': entry['startTime'],
        'endTime': entry['endTime'],
        'status': entry['status']
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
        'startTime': entry['startTime'],
        'endTime': entry['endTime'],
        'status': entry['status']
      };
    }).toList();
  }
}
