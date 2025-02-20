// lib/features/venue/services/venue_resident_artists_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/venue/models/isar_venue.dart';
import 'package:isar/isar.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class VenueResidentArtistsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();
  // Using the central Isar instance from DatabaseService
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves resident artists associated with a venue.
  /// - Online: fetches from Supabase, updates the local cache (residentArtists link in IsarVenue),
  ///   logs les IDs récupérés depuis le serveur, puis retourne la liste complète des Artist objects.
  /// - Offline: loads the cached resident artists from IsarVenue and logs les IDs présents dans le cache.
  Future<List<Artist>> getArtistsByVenueId(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('venue_resident_artists')
          .select('artist_id')
          .eq('venue_id', venueId);
      if ((response as List).isEmpty) {
        print(
            "getArtistsByVenueId: No resident artist assignments found for venueId $venueId (online).");
        return [];
      }
      // Extract artist IDs from response.
      final List<int> artistIds =
          response.map<int>((entry) => entry['artist_id'] as int).toList();
      print(
          "getArtistsByVenueId: Parsed artist IDs for venueId $venueId: $artistIds");

      // Update local cache: update the residentArtists link in the venue.
      final isarVenue =
          await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
      if (isarVenue != null) {
        await _updateResidentArtistsCache(isarVenue, artistIds, isar);
        await isarVenue.residentArtists.load();
        print(
            "getArtistsByVenueId: Cache updated for venueId $venueId, resident artists in cache: ${isarVenue.residentArtists.map((a) => a.remoteId).toList()}");
      }
      // Retrieve complete Artist objects via ArtistService.
      final List<Artist> artists =
          await _artistService.getArtistsByIds(artistIds);
      return artists;
    } else {
      // Offline: load cached resident artists from IsarVenue using the factorized helper.
      return await _loadArtistsByVenueFromCache(venueId, isar: isar);
    }
  }

  /// Retrieves venues associated with a given artist via the residentArtists relation.
  Future<List<Venue>> getVenuesByArtistId(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response = await _supabase
          .from('venue_resident_artists')
          .select('venue_id')
          .eq('artist_id', artistId);
      if ((response as List).isEmpty) return [];
      final List<int> venueIds =
          response.map<int>((item) => item['venue_id'] as int).toList();
      print(
          "getVenuesByArtistId: Remote venue IDs for artistId $artistId: $venueIds");
      return await _venueService.getVenuesByIds(venueIds);
    } else {
      return await _loadVenuesByResidentArtistFromCache(artistId, isar);
    }
  }

  /// Updates resident artists associated with a venue.
  Future<void> updateVenueArtists(int venueId, List<int> artistIds) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (!online) {
      throw Exception("No internet connection to update venue artists.");
    }
    // Delete existing entries on Supabase.
    await _supabase
        .from('venue_resident_artists')
        .delete()
        .eq('venue_id', venueId);
    // Insert new entries.
    final entries = artistIds
        .map((artistId) => {
              'venue_id': venueId,
              'artist_id': artistId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response = await _supabase
          .from('venue_resident_artists')
          .insert(entries)
          .select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update venue artists.');
      }
      print(
          "updateVenueArtists: Remote update successful for venueId $venueId, new artist IDs: $artistIds");
    }
    // Update local cache: update the residentArtists link in the venue.
    final isarVenue =
        await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
    if (isarVenue != null) {
      await _updateResidentArtistsCache(isarVenue, artistIds, isar);
      await isarVenue.residentArtists.load();
      final cachedIds =
          isarVenue.residentArtists.map((a) => a.remoteId).toList();
      print(
          "updateVenueArtists: Cache updated for venueId $venueId, cached artist IDs: $cachedIds");
    } else {
      print("updateVenueArtists: No venue found in cache for venueId $venueId");
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS (Local Cache)
  // --------------------------------------------------------------------------

  /// Helper method to update the residentArtists cache for a venue.
  Future<void> _updateResidentArtistsCache(
      IsarVenue venue, List<int> artistIds, Isar isar) async {
    await isar.writeTxn(() async {
      venue.residentArtists.clear();
      for (final id in artistIds) {
        final isarArtist =
            await isar.isarArtists.filter().remoteIdEqualTo(id).findFirst();
        if (isarArtist != null) {
          venue.residentArtists.add(isarArtist);
        } else {
          print("Warning: No artist found in cache for remoteId $id");
        }
      }
      await venue.residentArtists.save();
    });
  }

  /// Loads resident artists for a given venue from the local Isar cache.
  Future<List<Artist>> _loadArtistsByVenueFromCache(int venueId,
      {required Isar isar}) async {
    final isarVenue =
        await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
    if (isarVenue != null) {
      await isarVenue.residentArtists.load();
      final cachedArtistIds =
          isarVenue.residentArtists.map((a) => a.remoteId).toList();
      print(
          "Loaded cached resident artist IDs for venueId $venueId: $cachedArtistIds");
      return await _artistService.getArtistsByIds(cachedArtistIds);
    }
    print("No cached venue found for venueId $venueId.");
    return [];
  }

  /// Loads venues from cache for which the given artist is registered as a resident artist.
  Future<List<Venue>> _loadVenuesByResidentArtistFromCache(
      int artistId, Isar isar) async {
    try {
      final cachedVenues = await isar.isarVenues
          .filter()
          .residentArtists((q) => q.remoteIdEqualTo(artistId))
          .findAll();
      print(
          "Loaded cached venue IDs for artistId $artistId: ${cachedVenues.map((v) => v.remoteId).toList()}");
      return cachedVenues.map((isarVenue) {
        return Venue.fromJson({
          'id': isarVenue.remoteId,
          'name': isarVenue.name,
          'image_url': isarVenue.imageUrl,
          'description': isarVenue.description,
          'is_verified': isarVenue.isVerified,
        });
      }).toList();
    } catch (e) {
      print("Error in _loadVenuesByResidentArtistFromCache: $e");
      return [];
    }
  }
}
