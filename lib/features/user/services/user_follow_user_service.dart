import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowUserService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['followerId'] == userId && follow['followedId'] == targetUserId);
  }

  Future<void> followUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'followerId': userId, 'followedId': targetUserId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> unfollowUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['followerId'] == userId && follow['followedId'] == targetUserId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> saveUserFollowUserData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getFollowersCount(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['followedId'] == targetUserId).length;
  }

  Future<int> getFollowingCount(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['followerId'] == userId).length;
  }

  Future<List<User>> getFollowersForUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followerIds = followJson
        .where((follow) => follow['followedId'] == targetUserId)
        .map<String>((follow) => follow['followerId'] as String)
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }

  Future<List<User>> getFollowingForUser(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followingIds = followJson
        .where((follow) => follow['followerId'] == userId)
        .map<String>((follow) => follow['followedId'] as String)
        .toList();

    return await UserService().getUsersByIds(followingIds);
  }
}
