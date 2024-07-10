import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';

class OrganizerService {
  Future<List<Organizer>> getOrganizersWithEvents() async {
    print("Loading organizers with events from JSON");
    final String response = await rootBundle.loadString('assets/databases/organizers.json');
    final List<dynamic> organizerJson = json.decode(response) as List<dynamic>;

    // Charger les événements
    final List<Event> events = await EventService().getEvents();

    return organizerJson
        .map((json) => Organizer.fromJson(json as Map<String, dynamic>, events))
        .toList();
  }

  Future<Organizer?> getOrganizerByIdWithEvents(String id) async {
    final List<Organizer> organizers = await getOrganizersWithEvents();
    try {
      final Organizer organizer = organizers.firstWhere((organizer) => organizer.id == id);
      return organizer;
    } catch (e) {
      return null;
    }
  }

  Future<List<Organizer>> getOrganizers() async {
    print("Loading organizers from JSON");
    final String response = await rootBundle.loadString('assets/databases/organizers.json');
    final List<dynamic> organizerJson = json.decode(response) as List<dynamic>;

    return organizerJson
        .map((json) => Organizer.fromJsonWithoutEvents(json as Map<String, dynamic>))
        .toList();
  }

  Future<Organizer?> getOrganizerById(String id) async {
    final List<Organizer> organizers = await getOrganizers();
    try {
      final Organizer organizer = organizers.firstWhere((organizer) => organizer.id == id);
      return organizer;
    } catch (e) {
      return null;
    }
  }
}
