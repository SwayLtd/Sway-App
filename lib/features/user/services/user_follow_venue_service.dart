import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';

class UserFollowVenueService {
  Future<List<Venue>> getFollowedVenuesByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> userVenueJson = json.decode(response) as List<dynamic>;
    final venueIds = userVenueJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['venueId'] as String)
        .toList();

    final String venueResponse = await rootBundle.loadString('assets/databases/venues.json');
    final List<dynamic> venueJson = json.decode(venueResponse) as List<dynamic>;
    final venues = venueJson.map((json) => Venue.fromJson(json as Map<String, dynamic>)).toList();

    return venues.where((venue) => venueIds.contains(venue.id)).toList();
  }

  Future<int> getVenueFollowersCount(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_venue.json');
    final List<dynamic> userVenueJson = json.decode(response) as List<dynamic>;
    final count = userVenueJson.where((entry) => entry['venueId'] == venueId).length;
    return count;
  }
}
