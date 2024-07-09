// event_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';

class EventService {
  Future<List<Event>> getEvents() async {
    final String response = await rootBundle.loadString('assets/databases/events.json');
    final List<dynamic> eventJson = json.decode(response) as List<dynamic>;
    return eventJson.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Event> getEventById(String eventId) async {
    final events = await getEvents();
    return events.firstWhere((event) => event.id == eventId);
  }

  Future<List<Event>> searchEvents(String query) async {
    final events = await getEvents();
    return events.where((event) {
      final eventTitleLower = event.title.toLowerCase();
      final searchLower = query.toLowerCase();

      return eventTitleLower.contains(searchLower);
    }).toList();
  }
}
