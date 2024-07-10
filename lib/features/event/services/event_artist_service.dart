import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';

class EventArtistService {
  Future<List<Artist>> getArtistsByEventId(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson = json.decode(response) as List<dynamic>;
    final artistIds = eventArtistJson
        .where((entry) => entry['eventId'] == eventId)
        .map((entry) => entry['artistId'] as String)
        .toList();

    final artists = await ArtistService().getArtists();
    return artists.where((artist) => artistIds.contains(artist.id)).toList();
  }

  Future<List<Event>> getEventsByArtistId(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_artist.json');
    final List<dynamic> eventArtistJson = json.decode(response) as List<dynamic>;
    final eventIds = eventArtistJson
        .where((entry) => entry['artistId'] == artistId)
        .map((entry) => entry['eventId'] as String)
        .toList();

    final events = await EventService().getEvents();
    return events.where((event) => eventIds.contains(event.id)).toList();
  }
}
