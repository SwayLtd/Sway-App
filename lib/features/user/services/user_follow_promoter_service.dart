// user_follow_promoter_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';

class UserFollowPromoterService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['user_id'] == userId && follow['promoter_id'] == promoterId);
  }

  Future<void> followPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'user_id': userId, 'promoter_id': promoterId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowPromoterData(followJson);
  }

  Future<void> unfollowPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['user_id'] == userId && follow['promoter_id'] == promoterId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowPromoterData(followJson);
  }

  Future<void> saveUserFollowPromoterData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getPromoterFollowersCount(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['promoter_id'] == promoterId).length;
  }

  Future<List<Promoter>> getFollowedPromotersByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followedPromoterIds = followJson
        .where((follow) => follow['user_id'] == userId)
        .map<int>((follow) => follow['promoter_id'])
        .toList();

    final List<Promoter> allPromoters = await PromoterService().getPromoters();

    return allPromoters.where((promoter) => followedPromoterIds.contains(promoter.id)).toList();
  }

  Future<List<User>> getFollowersForPromoter(int promoterId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_promoter.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['promoter_id'] == promoterId)
        .map<int>((follow) => follow['user_id'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
