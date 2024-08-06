// user_follow_venue_service.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class UserFollowVenueService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingVenue(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['userId'] == userId && follow['venueId'] == venueId);
  }

  Future<void> followVenue(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'userId': userId, 'venueId': venueId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowVenueData(followJson);
  }

  Future<void> unfollowVenue(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['userId'] == userId && follow['venueId'] == venueId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowVenueData(followJson);
  }

  Future<void> saveUserFollowVenueData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getVenueFollowersCount(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['venueId'] == venueId).length;
  }

  Future<List<Venue>> getFollowedVenuesByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followedVenueIds = followJson
        .where((follow) => follow['userId'] == userId)
        .map<String>((follow) => follow['venueId'] as String)
        .toList();

    final List<Venue> allVenues = await VenueService().getVenues();

    return allVenues.where((venue) => followedVenueIds.contains(venue.id)).toList();
  }

  Future<List<User>> getFollowersForVenue(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List<String> followerIds = followJson
        .where((follow) => follow['venueId'] == venueId)
        .map<String>((follow) => follow['userId'] as String)
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
