import 'dart:convert';
import 'package:flutter/services.dart';

class ArtistGenreService {
  Future<List> getGenresByArtistId(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/artist_genre.json');
    final List<dynamic> artistGenreJson = json.decode(response) as List<dynamic>;
    return artistGenreJson
        .where((entry) => entry['artistId'] == artistId)
        .map<int>((entry) => entry['genreId']) // Cast to int explicitly
        .toList();
  }
}
