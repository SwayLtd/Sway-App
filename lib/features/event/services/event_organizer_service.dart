import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';

class EventOrganizerService {
  Future<List<Organizer>> getOrganizersByEventId(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_organizer.json');
    final List<dynamic> eventOrganizerJson = json.decode(response) as List<dynamic>;
    final organizerIds = eventOrganizerJson
        .where((entry) => entry['eventId'] == eventId)
        .map((entry) => entry['organizerId'] as String)
        .toList();

    final organizers = await OrganizerService().getOrganizers();
    return organizers.where((organizer) => organizerIds.contains(organizer.id)).toList();
  }
}
