// user_follow_venue_service.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class UserFollowVenueService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingVenue(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.any((follow) => follow['user_id'] == userId && follow['venue_id'] == venueId);
  }

  Future<void> followVenue(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.add({'user_id': userId, 'venue_id': venueId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowVenueData(followJson);
  }

  Future<void> unfollowVenue(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    followJson.removeWhere((follow) => follow['user_id'] == userId && follow['venue_id'] == venueId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserFollowVenueData(followJson);
  }

  Future<void> saveUserFollowVenueData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getVenueFollowersCount(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    return followJson.where((follow) => follow['venue_id'] == venueId).length;
  }

  Future<List<Venue>> getFollowedVenuesByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followedVenueIds = followJson
        .where((follow) => follow['user_id'] == userId)
        .map<int>((follow) => follow['venue_id'])
        .toList();

    final List<Venue> allVenues = await VenueService().getVenues();

    return allVenues.where((venue) => followedVenueIds.contains(venue.id)).toList();
  }

  Future<List<User>> getFollowersForVenue(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> followJson = json.decode(response) as List<dynamic>;

    final List followerIds = followJson
        .where((follow) => follow['venue_id'] == venueId)
        .map<int>((follow) => follow['user_id'])
        .toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
