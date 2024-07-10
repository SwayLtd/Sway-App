import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';

class ArtistService {
  Future<List<Artist>> getArtists() async {
    final String response = await rootBundle.loadString('assets/databases/artists.json');
    final List<dynamic> artistJson = json.decode(response) as List<dynamic>;
    return artistJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Artist?> getArtistById(String artistId) async {
    final List<Artist> artists = await getArtists();
    try {
      final Artist artist = artists.firstWhere((artist) => artist.id == artistId);
      return artist;
    } catch (e) {
      return null;
    }
  }

  Future<List<Artist>> getTopArtistsByGenreId(String genreId) async {
    final String artistGenreResponse = await rootBundle.loadString('assets/databases/join_table/artist_genre.json');
    final List<dynamic> artistGenreJson = json.decode(artistGenreResponse) as List<dynamic>;
    final artistIds = artistGenreJson
        .where((entry) => entry['genreId'] == genreId)
        .map((entry) => entry['artistId'] as String)
        .toList();

    final List<Artist> allArtists = await getArtists();
    final List<Artist> filteredArtists = allArtists.where((artist) => artistIds.contains(artist.id)).toList();

    // Tri des artistes par nombre de followers
    filteredArtists.sort((a, b) => b.followers.compareTo(a.followers));

    return filteredArtists;
  }
}
