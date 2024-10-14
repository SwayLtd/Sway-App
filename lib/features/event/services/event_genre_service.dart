import 'dart:convert';
import 'package:flutter/services.dart';

class EventGenreService {
  Future<List> getGenresByEventId(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_genre.json');
    final List<dynamic> eventGenreJson = json.decode(response) as List<dynamic>;
    return eventGenreJson
        .where((entry) => entry['event_id'] == eventId)
        .map((entry) => entry['genre_id'])
        .toList();
  }
}