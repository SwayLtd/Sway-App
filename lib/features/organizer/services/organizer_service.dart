import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';

class OrganizerService {
  Future<List<Organizer>> getOrganizers() async {
    final String response = await rootBundle.loadString('assets/organizers.json');
    final List<dynamic> organizerJson = json.decode(response) as List<dynamic>;
    return organizerJson.map((json) => Organizer.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Organizer?> getOrganizerById(String organizerId) async {
    final organizers = await getOrganizers();
    try {
      final organizer = organizers.firstWhere((organizer) => organizer.id == organizerId);
      print("Organizer found: ${organizer.id}");
      return organizer;
    } catch (e) {
      print("Organizer not found for ID: $organizerId");
      return null;
    }
  }
}
