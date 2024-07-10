import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';

class UserFollowOrganizerService {
  Future<List<Organizer>> getFollowedOrganizersByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> userOrganizerJson = json.decode(response) as List<dynamic>;
    final organizerIds = userOrganizerJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['organizerId'] as String)
        .toList();

    final String organizerResponse = await rootBundle.loadString('assets/databases/organizers.json');
    final List<dynamic> organizerJson = json.decode(organizerResponse) as List<dynamic>;
    final organizers = organizerJson.map((json) => Organizer.fromJsonWithoutEvents(json as Map<String, dynamic>)).toList();

    return organizers.where((organizer) => organizerIds.contains(organizer.id)).toList();
  }

  Future<int> getOrganizerFollowersCount(String organizerId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_follow_organizer.json');
    final List<dynamic> userOrganizerJson = json.decode(response) as List<dynamic>;
    final count = userOrganizerJson.where((entry) => entry['organizerId'] == organizerId).length;
    return count;
  }
}
