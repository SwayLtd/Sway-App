import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserFollowUserService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['follower_id'] == userId && follow['followed_id'] == targetUserId);
  }

  Future<void> followUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'follower_id': userId, 'followed_id': targetUserId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> unfollowUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['follower_id'] == userId && follow['followed_id'] == targetUserId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> saveUserFollowUserData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getFollowersCount(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['followed_id'] == targetUserId).length;
  }

  Future<int> getFollowingCount(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['follower_id'] == userId).length;
  }

  Future<List<User>> getFollowersForUser(int targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['followed_id'] == targetUserId)
        .map<int>((follow) => follow['follower_id'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }

  Future<List<User>> getFollowingForUser(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followingIds = followJson
        .where((follow) => follow['follower_id'] == userId)
        .map<int>((follow) => follow['followed_id'])
        .toList();

    return await UserService().getUsersByIds(followingIds);
  }
}
