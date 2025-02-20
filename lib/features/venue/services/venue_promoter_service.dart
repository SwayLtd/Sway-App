// lib/features/venue/services/venue_promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:isar/isar.dart';
import 'package:sway/features/venue/models/isar_venue.dart';

class VenuePromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PromoterService _promoterService = PromoterService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves promoters associated with a venue.
  /// - Online: fetches from Supabase, updates the local cache and returns the complete list.
  /// - Offline: loads promoters from the local cache.
  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('venue_promoter')
          .select('promoter_id')
          .eq('venue_id', venueId);
      if ((response as List).isEmpty) return [];

      final List<int> promoterIds =
          response.map<int>((entry) => entry['promoter_id'] as int).toList();
      print(
          "VenuePromoterService: Promoter IDs from Supabase for venueId $venueId: $promoterIds");

      // Update local cache
      final isarVenue =
          await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
      if (isarVenue != null) {
        await _updateVenuePromotersCache(isarVenue, promoterIds, isar);
        final cachedIds = await _loadVenuePromotersCache(isarVenue);
        print(
            "VenuePromoterService: Cache updated for venueId $venueId, cached promoter IDs: $cachedIds");
      }
      return await _promoterService.getPromotersByIds(promoterIds);
    } else {
      // Offline: read from cache
      final isarVenue =
          await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
      if (isarVenue != null) {
        final cachedIds = await _loadVenuePromotersCache(isarVenue);
        print(
            "VenuePromoterService (offline): Cached promoter IDs for venueId $venueId: $cachedIds");
        return await _promoterService.getPromotersByIds(cachedIds);
      }
      return [];
    }
  }

  /// Updates the promoters associated with a venue.
  Future<void> updateVenuePromoters(int venueId, List<int> promoterIds) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (!online) {
      throw Exception("No internet connection to update venue promoters.");
    }
    // Delete existing entries on Supabase.
    await _supabase.from('venue_promoter').delete().eq('venue_id', venueId);
    // Insert new entries.
    final entries = promoterIds
        .map((promoterId) => {
              'venue_id': venueId,
              'promoter_id': promoterId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('venue_promoter').insert(entries).select();
      if ((response as List).isEmpty) {
        throw Exception("Failed to update venue promoters.");
      }
    }
    // Update local cache.
    final isarVenue =
        await isar.isarVenues.filter().remoteIdEqualTo(venueId).findFirst();
    if (isarVenue != null) {
      await _updateVenuePromotersCache(isarVenue, promoterIds, isar);
      final cachedIds = await _loadVenuePromotersCache(isarVenue);
      print(
          "VenuePromoterService: Cache updated for venueId $venueId after update, cached promoter IDs: $cachedIds");
    }
  }

  // --------------------------------------------------------------------------
  // Helper Methods for Local Cache
  // --------------------------------------------------------------------------

  /// Updates the promoters link in a venue within a transaction.
  Future<void> _updateVenuePromotersCache(
      IsarVenue venue, List<int> promoterIds, Isar isar) async {
    await isar.writeTxn(() async {
      venue.promoters.clear();
      for (final id in promoterIds) {
        final isarPromoter =
            await isar.isarPromoters.filter().remoteIdEqualTo(id).findFirst();
        if (isarPromoter != null) {
          venue.promoters.add(isarPromoter);
        }
      }
      await venue.promoters.save();
    });
  }

  /// Loads the promoter IDs from a venue's cache.
  Future<List<int>> _loadVenuePromotersCache(IsarVenue venue) async {
    await venue.promoters.load();
    return venue.promoters.map((p) => p.remoteId).toList();
  }
}
