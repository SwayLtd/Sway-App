// user_follow_artist_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowArtistService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingArtist(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['userId'] == userId && follow['artistId'] == artistId);
  }

  Future<void> followArtist(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'artistId': artistId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowArtistData(followJson);
  }

  Future<void> unfollowArtist(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['userId'] == userId && follow['artistId'] == artistId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowArtistData(followJson);
  }

  Future<void> saveUserFollowArtistData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getArtistFollowersCount(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['artistId'] == artistId).length;
  }

  Future<List<Artist>> getFollowedArtistsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followedArtistIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<String>((follow) => follow['artistId'] as String)
        .toList();

    final List<Artist> allArtists = await ArtistService().getArtists();

    return allArtists.where((artist) => followedArtistIds.contains(artist.id)).toList();
  }

  Future<List<User>> getFollowersForArtist(String artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followerIds = followJson
        .where((follow) => follow['artistId'] == artistId)
        .map<String>((follow) => follow['userId'] as String)
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
