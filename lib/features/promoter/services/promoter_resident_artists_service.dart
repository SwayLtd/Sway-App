// lib/features/promoter/services/promoter_resident_artists_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:isar/isar.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class PromoterResidentArtistsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final PromoterService _promoterService = PromoterService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves resident artists associated with a promoter.
  /// - In online mode: fetches from Supabase, updates the local cache (the residentArtists link in IsarPromoter), and returns the full Artist objects.
  /// - In offline mode: loads the resident artists from the local cache.
  Future<List<Artist>> getArtistsByPromoterId(int promoterId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('promoter_resident_artists')
          .select('artist_id')
          .eq('promoter_id', promoterId);
      if ((response as List).isEmpty) {
        // print("getArtistsByPromoterId: No assignments found for promoterId $promoterId (online).");
        return [];
      }

      // Parse artist IDs from each assignment.
      final Set<int> artistIds = {};
      for (final entry in response) {
        artistIds.addAll(_parseArtistField(entry['artist_id']));
      }
      // print("getArtistsByPromoterId: Parsed artist IDs for promoterId $promoterId: $artistIds");

      // Update local cache: update the residentArtists link in the cached promoter.
      final isarPromoter = await isar.isarPromoters
          .filter()
          .remoteIdEqualTo(promoterId)
          .findFirst();
      if (isarPromoter != null) {
        await _updatePromoterResidentArtistsCache(
            isarPromoter, artistIds.toList(), isar);
        await isarPromoter.residentArtists.load();
        // print("getArtistsByPromoterId: Cache updated for promoterId $promoterId, resident artists in cache: ${isarPromoter.residentArtists.map((a) => a.remoteId).toList()}");
      }

      // Retrieve complete Artist objects via ArtistService.
      final List<Artist> artists =
          await _artistService.getArtistsByIds(artistIds.toList());
      // print("getArtistsByPromoterId: Artists retrieved via ArtistService: ${artists.map((a) => a.id).toList()}");
      return artists;
    } else {
      // Offline: load resident artists from local cache.
      final isar = await _isarFuture;
      final isarPromoter = await isar.isarPromoters
          .filter()
          .remoteIdEqualTo(promoterId)
          .findFirst();
      if (isarPromoter != null) {
        await isarPromoter.residentArtists.load();
        final List<Artist> cachedArtists = await _artistService.getArtistsByIds(
            isarPromoter.residentArtists.map((a) => a.remoteId).toList());
        // print("getArtistsByPromoterId (offline): Artists loaded from cache for promoterId $promoterId: ${cachedArtists.map((a) => a.id).toList()}");
        return cachedArtists;
      }
      // print("getArtistsByPromoterId (offline): No cached assignments found for promoterId $promoterId.");
      return [];
    }
  }

  Future<List<Promoter>> getPromotersByArtistId(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('promoter_resident_artists')
          .select('promoter_id')
          .eq('artist_id', artistId);
      if ((response as List).isEmpty) return [];
      final List<int> promoterIds =
          response.map<int>((entry) => entry['promoter_id'] as int).toList();
      return await _promoterService.getPromotersByIds(promoterIds);
    } else {
      // Offline: query local cache
      // We query the IsarPromoter collection where the residentArtists link contains an artist with remoteId == artistId.
      final isarPromoters = await isar.isarPromoters
          .filter()
          .residentArtists((q) => q.remoteIdEqualTo(artistId))
          .findAll();

      // Convert the cached IsarPromoter objects to Promoter objects.
      final List<Promoter> promoters = isarPromoters.map((isarPromoter) {
        return Promoter.fromJsonWithoutEvents({
          'id': isarPromoter.remoteId,
          'name': isarPromoter.name,
          'image_url': isarPromoter.imageUrl,
          'description': isarPromoter.description,
          'is_verified': isarPromoter.isVerified,
        });
      }).toList();

      return promoters;
    }
  }

  /// Adds an artist to a promoter on Supabase and updates the local cache.
  Future<void> addArtistToPromoter(int promoterId, int artistId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to add artist to promoter.");
    }
    final response = await _supabase.from('promoter_resident_artists').insert({
      'promoter_id': promoterId,
      'artist_id': artistId,
    }).select();
    if ((response as List).isEmpty) {
      throw Exception("Failed to add artist to promoter.");
    }
    // Update local cache: add the artist to the promoter's residentArtists link.
    final isar = await _isarFuture;
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await _storeArtistInPromoterCache(isarPromoter, artistId, isar);
      await isarPromoter.residentArtists.load();
      // print("addArtistToPromoter: Cache updated for promoterId $promoterId, resident artists in cache: ${isarPromoter.residentArtists.map((a) => a.remoteId).toList()}");
    }
  }

  /// Removes an artist from a promoter on Supabase and updates the local cache.
  Future<void> removeArtistFromPromoter(int promoterId, int artistId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to remove artist from promoter.");
    }
    final response = await _supabase
        .from('promoter_resident_artists')
        .delete()
        .eq('promoter_id', promoterId)
        .eq('artist_id', artistId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception("Failed to remove artist from promoter.");
    }
    // Update local cache: remove the artist from the promoter's residentArtists link.
    final isar = await _isarFuture;
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await isar.writeTxn(() async {
        await isarPromoter.residentArtists.load();
        isarPromoter.residentArtists.removeWhere((a) => a.remoteId == artistId);
        await isarPromoter.residentArtists.save();
      });
      // print("removeArtistFromPromoter: Cache updated for promoterId $promoterId, removed artistId $artistId");
    }
  }

  /// Updates the resident artists associated with a promoter on Supabase and updates the local cache.
  Future<void> updatePromoterArtists(
      int promoterId, List<int> artistIds) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (!online) {
      throw Exception('No internet connection to update promoter artists.');
    }

    // Delete existing entries on Supabase.
    await _supabase
        .from('promoter_resident_artists')
        .delete()
        .eq('promoter_id', promoterId);

    // Insert new entries.
    final entries = artistIds
        .map((artistId) => {
              'promoter_id': promoterId,
              'artist_id': artistId,
            })
        .toList();

    if (entries.isNotEmpty) {
      final response = await _supabase
          .from('promoter_resident_artists')
          .insert(entries)
          .select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update promoter artists.');
      }
    }

    // Update local cache.
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await _updatePromoterResidentArtistsCache(isarPromoter, artistIds, isar);
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE (Promoter Resident Artists Link)
  // --------------------------------------------------------------------------

  /// Factorized helper to update the residentArtists link in a cached promoter.
  Future<void> _updatePromoterResidentArtistsCache(
      IsarPromoter isarPromoter, List<int> artistIds, Isar isar) async {
    await isar.writeTxn(() async {
      isarPromoter.residentArtists.clear();
      for (final id in artistIds) {
        final isarArtist =
            await isar.isarArtists.filter().remoteIdEqualTo(id).findFirst();
        if (isarArtist != null) {
          isarPromoter.residentArtists.add(isarArtist);
        }
      }
      await isarPromoter.residentArtists.save();
    });
    // print("updatePromoterResidentArtistsCache: Cache updated for promoterId ${isarPromoter.remoteId}, resident artists in cache: ${isarPromoter.residentArtists.map((a) => a.remoteId).toList()}");
  }

  /// Factorized helper to add an artist link to a cached promoter.
  Future<void> _storeArtistInPromoterCache(
      IsarPromoter isarPromoter, int artistId, Isar isar) async {
    await isar.writeTxn(() async {
      await isarPromoter.residentArtists.load();
      if (!isarPromoter.residentArtists.any((a) => a.remoteId == artistId)) {
        final isarArtist = await isar.isarArtists
            .filter()
            .remoteIdEqualTo(artistId)
            .findFirst();
        if (isarArtist != null) {
          isarPromoter.residentArtists.add(isarArtist);
        }
      }
      await isarPromoter.residentArtists.save();
    });
  }

  /// Factorized helper to parse the artist_field into a Set<int>.
  Set<int> _parseArtistField(dynamic artistField) {
    final Set<int> ids = {};
    if (artistField is List) {
      ids.addAll(artistField.cast<int>());
    } else if (artistField is int) {
      ids.add(artistField);
    } else if (artistField is String) {
      final cleaned = artistField.replaceAll(RegExp(r'[\[\]]'), '');
      final parts = cleaned.split(',');
      for (final part in parts) {
        final id = int.tryParse(part.trim());
        if (id != null) {
          ids.add(id);
        }
      }
    }
    return ids;
  }
}
