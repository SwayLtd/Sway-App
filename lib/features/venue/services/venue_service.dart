// venue_service.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';

class VenueService {
  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Venue>> searchVenues(String query) async {
    final String response =
        await rootBundle.loadString('assets/databases/venues.json');
    final List<dynamic> venueJson = json.decode(response) as List<dynamic>;

    final venues = venueJson.map((json) {
      return Venue.fromJson(json as Map<String, dynamic>);
    }).toList();

    final results = venues.where((venue) {
      final matches = venue.name.toLowerCase().contains(query.toLowerCase());
      return matches;
    }).toList();

    return results;
  }

  Future<List<Venue>> getVenues() async {
    final String response =
        await rootBundle.loadString('assets/databases/venues.json');
    final List<dynamic> venueJson = json.decode(response) as List<dynamic>;
    return venueJson
        .map((json) => Venue.fromJson(json as Map<String, dynamic>))
        .toList();
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

  Future<List<Artist>> getResidentArtistsByVenueId(String venueId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_resident_artists.json');
    final List<dynamic> venueArtistJson =
        json.decode(response) as List<dynamic>;
    final artistIds = venueArtistJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['artistId'] as String)
        .toList();

    final artists = await ArtistService().getArtists();
    return artists.where((artist) => artistIds.contains(artist.id)).toList();
  }

  Future<List<Promoter>> getPromotersByVenueId(String venueId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_promoter.json');
    final List<dynamic> venuePromoterJson =
        json.decode(response) as List<dynamic>;
    final promoterIds = venuePromoterJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['promoterId'] as String)
        .toList();

    final promoters = await PromoterService().getPromoters();
    return promoters
        .where((promoter) => promoterIds.contains(promoter.id))
        .toList();
  }

  Future<List<Venue>> getVenuesByArtistId(String artistId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_resident_artists.json');
    final List<dynamic> venueArtistJson =
        json.decode(response) as List<dynamic>;
    final venueIds = venueArtistJson
        .where((entry) => entry['artistId'] == artistId)
        .map((entry) => entry['venueId'] as String)
        .toList();

    final venues = await getVenues();
    return venues.where((venue) => venueIds.contains(venue.id)).toList();
  }

  Future<void> addVenue(Venue venue) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        venue.id, 'venue', 'admin',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to add venue
  }

  Future<void> updateVenue(Venue venue) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        venue.id, 'venue', 'manager',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to update venue
  }

  Future<void> deleteVenue(String venueId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        venueId, 'venue', 'admin',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete venue
  }
}
