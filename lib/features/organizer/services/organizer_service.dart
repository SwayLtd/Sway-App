import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class OrganizerService {
  Future<List<Organizer>> searchOrganizers(String query) async {
    final String response =
        await rootBundle.loadString('assets/databases/organizers.json');
    final List<dynamic> organizerJson = json.decode(response) as List<dynamic>;

    final organizers = organizerJson.map((json) {
      return Organizer.fromJsonWithoutEvents(json as Map<String, dynamic>);
    }).toList();

    final results = organizers.where((organizer) {
      final matches =
          organizer.name.toLowerCase().contains(query.toLowerCase());
      return matches;
    }).toList();

    return results;
  }

  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Organizer>> getOrganizersWithEvents() async {
    final String response =
        await rootBundle.loadString('assets/databases/organizers.json');
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
      final Organizer organizer =
          organizers.firstWhere((organizer) => organizer.id == id);
      return organizer;
    } catch (e) {
      return null;
    }
  }

  Future<List<Organizer>> getOrganizers() async {
    final String response =
        await rootBundle.loadString('assets/databases/organizers.json');
    final List<dynamic> organizerJson = json.decode(response) as List<dynamic>;

    return organizerJson
        .map((json) =>
            Organizer.fromJsonWithoutEvents(json as Map<String, dynamic>))
        .toList();
  }

  Future<Organizer?> getOrganizerById(String id) async {
    final List<Organizer> organizers = await getOrganizers();
    try {
      final Organizer organizer =
          organizers.firstWhere((organizer) => organizer.id == id);
      return organizer;
    } catch (e) {
      return null;
    }
  }

  Future<void> addOrganizer(Organizer organizer) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        organizer.id, 'organizer', 'admin');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to add organizer
  }

  Future<void> updateOrganizer(Organizer organizer) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        organizer.id, 'organizer', 'manager');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to update organizer
  }

  Future<void> deleteOrganizer(String organizerId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        organizerId, 'organizer', 'admin');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete organizer
  }
}
