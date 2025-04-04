// lib/features/venue/services/venue_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';

// Import the regular Venue model used for API exchange and UI
import 'package:sway/features/venue/models/venue_model.dart';
// Import the Isar Venue model
import 'package:sway/features/venue/models/isar_venue.dart';
// Import related services (e.g., PromoterService)
import 'package:sway/features/promoter/services/promoter_service.dart';

class VenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  // Use the central Isar instance from DatabaseService
  late final Future<Isar> _isarFuture = DatabaseService().isar;
  final PromoterService _promoterService = PromoterService();

  /// Searches for venues by name.
  Future<List<Venue>> searchVenues(String query) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response =
          await _supabase.from('venues').select().ilike('name', '%$query%');
      if ((response as List).isEmpty) return [];
      final venues =
          response.map<Venue>((json) => Venue.fromJson(json)).toList();
      // Update local cache.
      for (final venue in venues) {
        await _storeVenueInIsar(isar, venue);
      }
      return venues;
    } else {
      // Offline: load all venues from local cache.
      return await _loadAllVenuesFromIsar(isar);
    }
  }

  /// Returns all venues.
  Future<List<Venue>> getVenues() async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase.from('venues').select();
        if ((response as List).isEmpty) {
          return await _loadAllVenuesFromIsar(isar);
        }
        final fetchedVenues =
            response.map<Venue>((json) => Venue.fromJson(json)).toList();
        for (final venue in fetchedVenues) {
          await _storeVenueInIsar(isar, venue);
        }
        return fetchedVenues;
      } catch (e) {
        debugPrint('Error in getVenues (online): $e');
        return await _loadAllVenuesFromIsar(isar);
      }
    } else {
      return await _loadAllVenuesFromIsar(isar);
    }
  }

  /// Returns a venue by ID using an offline-first approach.
  Future<Venue?> getVenueById(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase
            .from('venues')
            .select()
            .eq('id', venueId)
            .maybeSingle();
        if (response != null) {
          final venue = Venue.fromJson(response);
          await _storeVenueInIsar(isar, venue);
          return venue;
        } else {
          return await _loadVenueFromIsar(venueId, isar: isar);
        }
      } catch (e) {
        debugPrint('Error in getVenueById (online): $e');
        return await _loadVenueFromIsar(venueId, isar: isar);
      }
    } else {
      return await _loadVenueFromIsar(venueId, isar: isar);
    }
  }

  /// Returns promoters associated with a given venue.
  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final online = await isConnected();
    if (online) {
      final response = await _supabase
          .from('venue_promoter')
          .select('promoter_id')
          .eq('venue_id', venueId);
      if ((response as List).isEmpty) return [];
      final List<int> promoterIds =
          response.map<int>((entry) => entry['promoter_id'] as int).toList();
      return await _promoterService.getPromotersByIds(promoterIds);
    } else {
      // Offline: implement cache reading if desired.
      return [];
    }
  }

  /// Returns venues by a list of IDs.
  Future<List<Venue>> getVenuesByIds(List<int> venueIds) async {
    if (venueIds.isEmpty) return [];
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final ids = '(${venueIds.join(',')})';
      final response =
          await _supabase.from('venues').select().filter('id', 'in', ids);
      if ((response as List).isEmpty) return [];
      final venues =
          response.map<Venue>((json) => Venue.fromJson(json)).toList();
      for (final venue in venues) {
        await _storeVenueInIsar(isar, venue);
      }
      return venues;
    } else {
      return await _loadAllVenuesFromIsar(isar);
    }
  }

  /// Adds a new venue.
  Future<Venue> addVenue(Venue venue) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection to add venue.");
    // Use the model's toJson() to include location_point if latitude and longitude are provided.
    final venueData = venue.toJson();
    final response =
        await _supabase.from('venues').insert(venueData).select().single();
    final newVenue = Venue.fromJson(response);
    final isar = await _isarFuture;
    await _storeVenueInIsar(isar, newVenue);
    return newVenue;
  }

  /// Updates an existing venue.
  Future<Venue> updateVenue(Venue venue) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection to update venue.");
    final response = await _supabase
        .from('venues')
        .update(venue.toJson())
        .eq('id', venue.id!)
        .select()
        .single();
    final updatedVenue = Venue.fromJson(response);
    final isar = await _isarFuture;
    await _storeVenueInIsar(isar, updatedVenue);
    return updatedVenue;
  }

  /// Deletes a venue by ID.
  Future<void> deleteVenue(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response =
          await _supabase.from('venues').delete().eq('id', venueId).select();
      if ((response as List).isEmpty) {
        throw Exception("Failed to delete venue on server.");
      }
    }
    // Delete venue from local cache.
    await isar.writeTxn(() async {
      await isar.isarVenues.filter().remoteIdEqualTo(venueId).deleteAll();
    });
  }

  /// Returns venues filtered by genre ID.
  Future<List<Venue>> getVenuesByGenreId(int genreId) async {
    final online = await isConnected();
    if (online) {
      final response = await _supabase
          .from('venue_genre')
          .select('venue_id')
          .eq('genre_id', genreId);
      if ((response as List).isEmpty) return [];
      final venueIds =
          response.map<int>((item) => item['venue_id'] as int).toList();
      return await getVenuesByIds(venueIds);
    } else {
      final isar = await _isarFuture;
      // Offline: if a proper cache exists, implement filtering here.
      final allVenues = await _loadAllVenuesFromIsar(isar);
      // Example: filtering by genre could be implemented if the cached venue model includes genre info.
      return allVenues
          .where((v) => false)
          .toList(); // To be implemented if needed.
    }
  }

  /// Returns recommended venues by calling a Supabase RPC.
  Future<List<Venue>> getRecommendedVenues({int? userId, int limit = 5}) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    final params = <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
    };

    try {
      final response =
          await _supabase.rpc('get_recommended_venues', params: params);
      if (response == null || (response as List).isEmpty) return [];
      final venues = (response)
          .map<Venue>((json) => Venue.fromJson(json as Map<String, dynamic>))
          .toList();
      if (online) {
        // Cache each venue if desired.
        for (final venue in venues) {
          await _storeVenueInIsar(isar, venue);
        }
      }
      return venues;
    } catch (e) {
      return await _loadAllVenuesFromIsar(isar);
    }
  }
}

// --------------------------------------------------------------------------
// HELPER METHODS FOR VENUES (Local Cache)
// --------------------------------------------------------------------------

/// Stores a Venue in Isar.
Future<void> _storeVenueInIsar(Isar isar, Venue venue) async {
  await isar.writeTxn(() async {
    final isarVenue = IsarVenue()
      ..remoteId = venue.id ?? 0
      ..name = venue.name
      ..imageUrl = venue.imageUrl
      ..description = venue.description
      ..location = venue.location
      ..isVerified = venue.isVerified;
    // TODO: Add linking for residentArtists, genres, upcomingEvents if needed.
    await isar.isarVenues.put(isarVenue);
  });
}

/// Loads a single Venue from Isar by remoteId.
Future<Venue?> _loadVenueFromIsar(int venueId, {required Isar isar}) async {
  final isarVenue =
      await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
  if (isarVenue == null) return null;
  return Venue.fromJson({
    'id': isarVenue.remoteId,
    'name': isarVenue.name,
    'image_url': isarVenue.imageUrl,
    'description': isarVenue.description,
    'location': isarVenue.location,
    'is_verified': isarVenue.isVerified,
    // If needed, add location and other fields here.
  });
}

/// Loads all Venues from Isar.
Future<List<Venue>> _loadAllVenuesFromIsar(Isar isar) async {
  final isarVenues = await isar.isarVenues.where().findAll();
  return isarVenues.map((isarVenue) {
    return Venue.fromJson({
      'id': isarVenue.remoteId,
      'name': isarVenue.name,
      'image_url': isarVenue.imageUrl,
      'description': isarVenue.description,
      'is_verified': isarVenue.isVerified,
    });
  }).toList();
}
