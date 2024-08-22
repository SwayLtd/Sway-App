import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowUserService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['followerId'] == userId && follow['followedId'] == targetUserId);
  }

  Future<void> followUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'followerId': userId, 'followedId': targetUserId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> unfollowUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['followerId'] == userId && follow['followedId'] == targetUserId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> saveUserFollowUserData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getFollowersCount(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['followedId'] == targetUserId).length;
  }

  Future<int> getFollowingCount(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['followerId'] == userId).length;
  }

  Future<List<User>> getFollowersForUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['followedId'] == targetUserId)
        .map<int>((follow) => follow['followerId'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }

  Future<List<User>> getFollowingForUser(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followingIds = followJson
        .where((follow) => follow['followerId'] == userId)
        .map<int>((follow) => follow['followedId'])
        .toList();

    return await UserService().getUsersByIds(followingIds);
  }
}
