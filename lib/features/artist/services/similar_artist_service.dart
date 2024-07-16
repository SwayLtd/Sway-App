// similar_artist_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';

class SimilarArtistService {
  Future<List<String>> getSimilarArtistsByArtistId(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/similar_artists.json');
    final List<dynamic> similarArtistJson = json.decode(response) as List<dynamic>;
    return similarArtistJson
        .where((entry) => entry['artistId'] == artistId)
        .map((entry) => entry['similarArtistId'] as String)
        .toList();
  }
}
