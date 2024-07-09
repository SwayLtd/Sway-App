// venue_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';

class VenueService {
  Future<List<Venue>> getVenues() async {
    final String response = await rootBundle.loadString('assets/databases/venues.json');
    final List<dynamic> venueJson = json.decode(response) as List<dynamic>;
    return venueJson.map((json) => Venue.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Venue?> getVenueById(String venueId) async {
    final List<Venue> venues = await getVenues();
    try {
      final Venue venue = venues.firstWhere((venue) => venue.id == venueId);
      return venue;
    } catch (e) {
      return null;
    }
  }
}
