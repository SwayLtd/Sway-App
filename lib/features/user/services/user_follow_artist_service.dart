// user_follow_artist_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserFollowArtistService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingArtist(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['user_id'] == userId && follow['artist_id'] == artistId);
  }

  Future<void> followArtist(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'user_id': userId, 'artist_id': artistId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowArtistData(followJson);
  }

  Future<void> unfollowArtist(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['user_id'] == userId && follow['artist_id'] == artistId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowArtistData(followJson);
  }

  Future<void> saveUserFollowArtistData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getArtistFollowersCount(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['artist_id'] == artistId).length;
  }

  Future<List<Artist>> getFollowedArtistsByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followedArtistIds = followJson
        .where((follow) => follow['user_id'] == userId)
        .map<int>((follow) => follow['artist_id'])
        .toList();

    final List<Artist> allArtists = await ArtistService().getArtists();

    return allArtists.where((artist) => followedArtistIds.contains(artist.id)).toList();
  }

  Future<List<User>> getFollowersForArtist(int artistId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_artist.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['artist_id'] == artistId)
        .map<int>((follow) => follow['user_id'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
