// lib/features/venue/services/venue_genre_service.dart

import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

class VenueGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves genre IDs associated with a venue.
  /// - Online: fetches from Supabase, updates the local cache for the venue, and returns the genre IDs.
  /// - Offline: loads the genre IDs from the cached IsarVenue.
  Future<List<int>> getGenresByVenueId(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response = await _supabase
          .from('venue_genre')
          .select('genre_id')
          .eq('venue_id', venueId);
      if ((response as List).isEmpty) return [];
      final genreIds =
          response.map<int>((entry) => entry['genre_id'] as int).toList();
      // Update local cache for the venue.
      final isarVenue =
          await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
      if (isarVenue != null) {
        await _updateVenueGenresCache(isarVenue, genreIds, isar);
        final cachedGenreIds = await _loadVenueGenresCache(isarVenue);
        print(
            "getGenresByVenueId: Cache updated for venueId $venueId, cached genre IDs: $cachedGenreIds");
      }
      return genreIds;
    } else {
      // Offline: read from cache.
      final isarVenue =
          await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
      if (isarVenue != null) {
        final cachedGenreIds = await _loadVenueGenresCache(isarVenue);
        return cachedGenreIds;
      }
      return [];
    }
  }

  /// Updates the genres associated with a venue on the server and in the local cache.
  Future<void> updateVenueGenres(int venueId, List<int> genreIds) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (!online) {
      throw Exception("No internet connection to update venue genres.");
    }
    // Delete existing entries on Supabase.
    await _supabase.from('venue_genre').delete().eq('venue_id', venueId);
    // Insert new entries.
    final entries = genreIds
        .map((genreId) => {
              'venue_id': venueId,
              'genre_id': genreId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('venue_genre').insert(entries).select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update venue genres.');
      }
    }
    // Update local cache.
    final isarVenue =
        await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
    if (isarVenue != null) {
      await _updateVenueGenresCache(isarVenue, genreIds, isar);
      final cachedGenreIds = await _loadVenueGenresCache(isarVenue);
      print(
          "updateVenueGenres: Cache updated for venueId $venueId, cached genre IDs: $cachedGenreIds");
    }
  }

  // --------------------------------------------------------------------------
  // Helper Methods for Local Cache
  // --------------------------------------------------------------------------

  /// Factorized helper to update the genre links in a cached venue.
  Future<void> _updateVenueGenresCache(
      IsarVenue venue, List<int> genreIds, Isar isar) async {
    await isar.writeTxn(() async {
      venue.genres.clear();
      for (final id in genreIds) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(id).findFirst();
        if (isarGenre != null) {
          venue.genres.add(isarGenre);
        }
      }
      await venue.genres.save();
    });
  }

  /// Factorized helper to load the genre IDs from a cached venue.
  Future<List<int>> _loadVenueGenresCache(IsarVenue venue) async {
    await venue.genres.load();
    return venue.genres.map((g) => g.remoteId).toList();
  }
}
