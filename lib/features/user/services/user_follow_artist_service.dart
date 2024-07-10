import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';

class UserFollowArtistService {
  Future<List<Artist>> getFollowedArtistsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> userArtistJson = json.decode(response) as List<dynamic>;
    final artistIds = userArtistJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['artistId'] as String)
        .toList();

    final String artistResponse = await rootBundle.loadString('assets/databases/artists.json');
    final List<dynamic> artistJson = json.decode(artistResponse) as List<dynamic>;
    final artists = artistJson.map((json) => Artist.fromJson(json as Map<String, dynamic>)).toList();

    return artists.where((artist) => artistIds.contains(artist.id)).toList();
  }

  Future<int> getArtistFollowersCount(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> userArtistJson = json.decode(response) as List<dynamic>;
    final count = userArtistJson.where((entry) => entry['artistId'] == artistId).length;
    return count;
  }
}
