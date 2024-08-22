// user_follow_promoter_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserFollowPromoterService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['userId'] == userId && follow['promoterId'] == promoterId);
  }

  Future<void> followPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'promoterId': promoterId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowPromoterData(followJson);
  }

  Future<void> unfollowPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['userId'] == userId && follow['promoterId'] == promoterId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowPromoterData(followJson);
  }

  Future<void> saveUserFollowPromoterData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getPromoterFollowersCount(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['promoterId'] == promoterId).length;
  }

  Future<List<Promoter>> getFollowedPromotersByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followedPromoterIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<int>((follow) => follow['promoterId'])
        .toList();

    final List<Promoter> allPromoters = await PromoterService().getPromoters();

    return allPromoters.where((promoter) => followedPromoterIds.contains(promoter.id)).toList();
  }

  Future<List<User>> getFollowersForPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['promoterId'] == promoterId)
        .map<int>((follow) => follow['userId'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
