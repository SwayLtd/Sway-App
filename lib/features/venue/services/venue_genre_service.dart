import 'dart:convert';
import 'package:flutter/services.dart';

class VenueGenreService {
  Future<List<String>> getGenresByVenueId(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/venue_genres.json');
    final List<dynamic> venueGenreJson = json.decode(response) as List<dynamic>;
    return venueGenreJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['genreId'] as String)
        .toList();
  }
}
