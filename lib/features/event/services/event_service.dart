// event_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/user/models/user_event_ticket_model.dart';
import 'package:sway_events/features/user/services/user_event_ticket_service.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class EventService {
  final UserPermissionService _permissionService = UserPermissionService();
  final UserEventTicketService _userEventTicketService = UserEventTicketService();

  Future<List<Event>> getEvents() async {
    final String response = await rootBundle.loadString('assets/databases/events.json');
    final List<dynamic> eventJson = json.decode(response) as List<dynamic>;
    return eventJson.map((json) => Event.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Event> getEventById(String eventId) async {
    final events = await getEvents();
    return events.firstWhere((event) => event.id == eventId);
  }

  Future<List<Event>> searchEvents(String query, Map<String, dynamic> filters) async {
    final events = await getEvents();
    final genres = await _getEventGenres();

    return events.where((event) {
      final eventTitleLower = event.title.toLowerCase();
      final searchLower = query.toLowerCase();
      bool matchesQuery = eventTitleLower.contains(searchLower);

      String? cityFilter = filters['city'] as String?;
      DateTime? dateFilter = filters['date'] as DateTime?;
      List<String>? genreFilter = (filters['genres'] as List<dynamic>?)?.cast<String>();
      bool nearMeFilter = filters['nearMe'] as bool? ?? false;

      bool matchesCity = cityFilter == null || event.venue == cityFilter;
      bool matchesDate = dateFilter == null || event.dateTime.startsWith(dateFilter.toString().split(' ')[0]);
      bool matchesGenre = genreFilter == null || genreFilter.isEmpty || genreFilter.any((genre) => genres[event.id]?.contains(genre) == true);
      bool matchesNearMe = !nearMeFilter; // Implement the "near me" logic later

      return matchesQuery && matchesCity && matchesDate && matchesGenre && matchesNearMe;
    }).toList();
  }

  Future<Map<String, List<String>>> _getEventGenres() async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_genre.json');
    final List<dynamic> genreJson = json.decode(response) as List<dynamic>;
    final Map<String, List<String>> eventGenres = {};

    for (var entry in genreJson) {
      final eventId = entry['eventId'] as String;
      final genreId = entry['genreId'] as String;
      eventGenres.putIfAbsent(eventId, () => []).add(genreId);
    }

    return eventGenres;
  }

  Future<void> addEvent(Event event) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(event.id, 'event', 'admin');
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
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(eventId, 'event', 'admin');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete event
  }

  Future<List<UserEventTicket>> getUserTicketsForEvent(String eventId) async {
    return await _userEventTicketService.getTicketsByEventId(eventId);
  }

  // Ajout de la méthode getEventsByIds
  Future<List<Event>> getEventsByIds(List<String> eventIds) async {
    final events = await getEvents();
    return events.where((event) => eventIds.contains(event.id)).toList();
  }

  Future<DateTime?> getFestivalStartTime(String eventId) async {
  final String response = await rootBundle.loadString('assets/databases/events.json');
  final List<dynamic> eventsJson = json.decode(response) as List<dynamic>;

  final event = eventsJson.firstWhere((event) => event['id'] == eventId, orElse: () => null);
  if (event != null) {
    return DateTime.parse(event['dateTime'] as String);
  }
  return null;
}
}
