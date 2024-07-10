import 'dart:convert';
import 'package:flutter/services.dart';

class ArtistGenreService {
  Future<List<String>> getGenresByArtistId(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/artist_genre.json');
    final List<dynamic> artistGenreJson = json.decode(response) as List<dynamic>;
    return artistGenreJson
        .where((entry) => entry['artistId'] == artistId)
        .map((entry) => entry['genreId'] as String)
        .toList();
  }
}
