import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';

class VenueOrganizerService {
  Future<List<Organizer>> getOrganizersByVenueId(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/venue_organizers.json');
    final List<dynamic> venueOrganizerJson = json.decode(response) as List<dynamic>;
    final organizerIds = venueOrganizerJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['organizerId'] as String)
        .toList();

    final organizers = await OrganizerService().getOrganizers();

    final venueOrganizers = organizers.where((organizer) => organizerIds.contains(organizer.id)).toList();

    return venueOrganizers;
  }
}
