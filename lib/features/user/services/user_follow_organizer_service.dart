import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';

class UserFollowOrganizerService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingOrganizer(String organizerId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['userId'] == userId && follow['organizerId'] == organizerId);
  }

  Future<void> followOrganizer(String organizerId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'organizerId': organizerId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowOrganizerData(followJson);
  }

  Future<void> unfollowOrganizer(String organizerId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['userId'] == userId && follow['organizerId'] == organizerId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowOrganizerData(followJson);
  }

  Future<void> saveUserFollowOrganizerData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getOrganizerFollowersCount(String organizerId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['organizerId'] == organizerId).length;
  }

  Future<List<Organizer>> getFollowedOrganizersByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followedOrganizerIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<String>((follow) => follow['organizerId'] as String)
        .toList();

    final List<Organizer> allOrganizers = await OrganizerService().getOrganizers();

    return allOrganizers.where((organizer) => followedOrganizerIds.contains(organizer.id)).toList();
  }
}
