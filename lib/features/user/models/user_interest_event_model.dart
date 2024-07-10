import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';

class UserInterestEventService {
  Future<List<Event>> getInterestedEventsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> userEventJson = json.decode(response) as List<dynamic>;
    final eventIds = userEventJson
        .where((entry) => entry['userId'] == userId)
        .map((entry) => entry['eventId'] as String)
        .toList();

    final String eventResponse = await rootBundle.loadString('assets/databases/events.json');
    final List<dynamic> eventJson = json.decode(eventResponse) as List<dynamic>;
    final events = eventJson.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();

    return events.where((event) => eventIds.contains(event.id)).toList();
  }

  Future<int> getEventInterestCount(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> userEventJson = json.decode(response) as List<dynamic>;
    final count = userEventJson.where((entry) => entry['eventId'] == eventId).length;
    return count;
  }
}
