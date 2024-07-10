import 'dart:convert';
import 'package:flutter/services.dart';

class EventGenreService {
  Future<List<String>> getGenresByEventId(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_genre.json');
    final List<dynamic> eventGenreJson = json.decode(response) as List<dynamic>;
    return eventGenreJson
        .where((entry) => entry['eventId'] == eventId)
        .map((entry) => entry['genreId'] as String)
        .toList();
  }
}
