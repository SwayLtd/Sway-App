// event_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class EventService {
  final UserPermissionService _permissionService = UserPermissionService();

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

  Future<void> addEvent(Event event) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(event.id, 'event', 'owner');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to add event
  }

  Future<void> updateEvent(Event event) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(event.id, 'event', 'manager');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to update event
  }

  Future<void> deleteEvent(String eventId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(eventId, 'event', 'owner');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete event
  }
}
