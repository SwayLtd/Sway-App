import 'dart:convert';
import 'package:flutter/services.dart';

class UserFollowUserService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['userId'] == userId && follow['targetUserId'] == targetUserId);
  }

  Future<void> followUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'targetUserId': targetUserId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> unfollowUser(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['userId'] == userId && follow['targetUserId'] == targetUserId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowUserData(followJson);
  }

  Future<void> saveUserFollowUserData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getFollowersCount(String targetUserId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['targetUserId'] == targetUserId).length;
  }

  Future<int> getFollowingCount(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_user.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['userId'] == userId).length;
  }
}
