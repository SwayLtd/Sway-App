// venue_service.dart

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class VenueService {
  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Venue>> searchVenues(String query) async {
    final String response =
        await rootBundle.loadString('assets/databases/venues.json');
    final List venueJson = json.decode(response);

    final venues = venueJson.map((json) {
      return Venue.fromJson(json);
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
    final List venueJson = json.decode(response);
    return venueJson
        .map((json) => Venue.fromJson(json))
        .toList();
  }

  Future<Venue?> getVenueById(int venueId) async {
    final List<Venue> venues = await getVenues();
    try {
      final Venue venue = venues.firstWhere((venue) => venue.id == venueId);
      return venue;
    } catch (e) {
      return null;
    }
  }

  Future<List<Artist>> getResidentArtistsByVenueId(int venueId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_resident_artists.json');
    final List venueArtistJson =
        json.decode(response);
    final artistIds = venueArtistJson
        .where((entry) => entry['venue_id'] == venueId)
        .map((entry) => entry['artist_id'])
        .toList();

    final artists = await ArtistService().getArtists();
    return artists.where((artist) => artistIds.contains(artist.id)).toList();
  }

  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_promoter.json');
    final List venuePromoterJson =
        json.decode(response);
    final promoterIds = venuePromoterJson
        .where((entry) => entry['venue_id'] == venueId)
        .map((entry) => entry['promoter_id'])
        .toList();

    final promoters = await PromoterService().getPromoters();
    return promoters
        .where((promoter) => promoterIds.contains(promoter.id))
        .toList();
  }

  Future<List<Venue>> getVenuesByArtistId(int artistId) async {
    final String response = await rootBundle
        .loadString('assets/databases/join_table/venue_resident_artists.json');
    final List venueArtistJson =
        json.decode(response);
    final venueIds = venueArtistJson
        .where((entry) => entry['artist_id'] == artistId)
        .map((entry) => entry['venue_id'])
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

  Future<void> deleteVenue(int venueId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        venueId, 'venue', 'admin',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete venue
  }
}
