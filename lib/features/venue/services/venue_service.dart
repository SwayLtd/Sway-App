// lib/features/venue/services/venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class VenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();

  Future<List<Venue>> searchVenues(String query) async {
    final response =
        await _supabase.from('venues').select().ilike('name', '%$query%');

    if (response.isEmpty) {
      print('No venues found.');
      return [];
    }

    return response.map<Venue>((json) => Venue.fromJson(json)).toList();
  }

  Future<List<Venue>> getVenues() async {
    final response = await _supabase.from('venues').select();

    if (response.isEmpty) {
      throw Exception('No venues found.');
    }

    return response.map<Venue>((json) => Venue.fromJson(json)).toList();
  }

  Future<Venue?> getVenueById(int venueId) async {
    final response =
        await _supabase.from('venues').select().eq('id', venueId).maybeSingle();

    if (response == null) {
      return null;
    }

    return Venue.fromJson(response);
  }

  Future<List<Artist>> getResidentArtistsByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_resident_artists')
        .select('artist_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> artistIds =
        response.map((item) => item['artist_id'] as int).toList();

    return await _artistService.getArtistsByIds(artistIds);
  }

  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_promoters')
        .select('promoter_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> promoterIds =
        response.map((item) => item['promoter_id'] as int).toList();

    return await _promoterService.getPromotersByIds(promoterIds);
  }

  Future<List<Venue>> getVenuesByIds(List<int> venueIds) async {
    if (venueIds.isEmpty) {
      return [];
    }

    // Convertir la liste d'IDs en une chaîne séparée par des virgules et entourée de parenthèses
    final String ids = '(${venueIds.join(',')})';

    final response = await _supabase
        .from('venues')
        .select()
        .filter('id', 'in', ids); // Utilisation correcte de .filter avec 'in'

    if (response.isEmpty) {
      return [];
    }

    return response.map<Venue>((json) => Venue.fromJson(json)).toList();
  }

  Future<void> addVenue(Venue venue) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      venue.id,
      'venue',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase.from('venues').insert(venue.toJson());

    if (response.isEmpty) {
      throw Exception('Failed to add venue.');
    }
  }

  Future<void> updateVenue(Venue venue) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      venue.id,
      'venue',
      'manager',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase
        .from('venues')
        .update(venue.toJson())
        .eq('id', venue.id);

    if (response.isEmpty) {
      throw Exception('Failed to update venue.');
    }
  }

  Future<void> deleteVenue(int venueId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      venueId,
      'venue',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase.from('venues').delete().eq('id', venueId);

    if (response.isEmpty) {
      throw Exception('Failed to delete venue.');
    }
  }

  Future<List<Venue>> getVenuesByGenreId(int genreId) async {
    final response = await _supabase
        .from('venue_genre')
        .select('venue_id')
        .eq('genre_id', genreId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> venueIds =
        response.map((item) => item['venue_id'] as int).toList();

    return await getVenuesByIds(venueIds);
  }
}
