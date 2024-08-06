// user_follow_genre_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/services/genre_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowGenreService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingGenre(String genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any(
        (follow) => follow['userId'] == userId && follow['genreId'] == genreId,);
  }

  Future<void> followGenre(String genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'genreId': genreId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowGenreData(followJson);
  }

  Future<void> unfollowGenre(String genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere(
        (follow) => follow['userId'] == userId && follow['genreId'] == genreId,);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowGenreData(followJson);
  }

  Future<void> saveUserFollowGenreData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getGenreFollowersCount(String genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['genreId'] == genreId).length;
  }

  Future<List<Genre>> getFollowedGenresByUserId(String userId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followedGenreIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<String>((follow) => follow['genreId'] as String)
        .toList();

    final List<Genre> allGenres = await GenreService().getGenres();

    return allGenres
        .where((genre) => followedGenreIds.contains(genre.id))
        .toList();
  }

  Future<List<User>> getUsersFollowingGenre(String genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> userIds = followJson
        .where((follow) => follow['genreId'] == genreId)
        .map<String>((follow) => follow['userId'] as String)
        .toList();

    return await UserService().getUsersByIds(userIds);
  }
}
