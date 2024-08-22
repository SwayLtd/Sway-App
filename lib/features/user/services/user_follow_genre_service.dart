// user_follow_genre_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/services/genre_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowGenreService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingGenre(int genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any(
        (follow) => follow['userId'] == userId && follow['genreId'] == genreId,);
  }

  Future<void> followGenre(int genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'genreId': genreId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowGenreData(followJson);
  }

  Future<void> unfollowGenre(int genreId) async {
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

  Future<int> getGenreFollowersCount(int genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['genreId'] == genreId).length;
  }

  Future<List<Genre>> getFollowedGenresByUserId(int userId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followedGenreIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<int>((follow) => follow['genreId'])
        .toList();

    final List<Genre> allGenres = await GenreService().getGenres();

    return allGenres
        .where((genre) => followedGenreIds.contains(genre.id))
        .toList();
  }

  Future<List<User>> getUsersFollowingGenre(int genreId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/user_follow_genre.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List userIds = followJson
        .where((follow) => follow['genreId'] == genreId)
        .map<int>((follow) => follow['userId'])
        .toList();

    return await UserService().getUsersByIds(userIds);
  }
}
