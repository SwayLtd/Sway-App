import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:sway/features/event/models/isar_event.dart';

class EventPromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PromoterService _promoterService = PromoterService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves promoters associated with a specific event.
  /// In online mode, it fetches from Supabase, updates the local cache (event.promoters link),
  /// and returns the list of promoters.
  /// In offline mode, it loads the promoters from the local cache.
  Future<List<Promoter>> getPromotersByEventId(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('event_promoter')
          .select('promoter_id')
          .eq('event_id', eventId);
      if ((response as List).isEmpty) return [];
      final List<int> promoterIds =
          response.map<int>((entry) => entry['promoter_id'] as int).toList();

      // Update local cache for the event.
      final isarEvent =
          await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
      if (isarEvent != null) {
        await _updateEventPromotersCache(isarEvent, promoterIds, isar);
      }
      return await _promoterService.getPromotersByIds(promoterIds);
    } else {
      // Offline: use the helper to load from the cache.
      return await _loadCachedPromoters(eventId, isar);
    }
  }

  /// Adds a promoter to an event on Supabase and updates the local cache.
  Future<void> addPromoterToEvent(int eventId, int promoterId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to add promoter to event.");
    }
    final response = await _supabase.from('event_promoter').insert({
      'event_id': eventId,
      'promoter_id': promoterId,
    }).select();
    if ((response as List).isEmpty) {
      throw Exception("Failed to add promoter to event.");
    }
    // Update local cache: add the promoter to the event's link.
    final isar = await _isarFuture;
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent != null) {
      await _storePromoterInEventCache(isarEvent, promoterId, isar);
    }
  }

  /// Removes a promoter from an event on Supabase and updates the local cache.
  Future<void> removePromoterFromEvent(int eventId, int promoterId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to remove promoter from event.");
    }
    final response = await _supabase
        .from('event_promoter')
        .delete()
        .eq('event_id', eventId)
        .eq('promoter_id', promoterId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception("Failed to remove promoter from event.");
    }
    // Update local cache: remove the corresponding link.
    final isar = await _isarFuture;
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent != null) {
      await isar.writeTxn(() async {
        await isarEvent.promoters.load();
        isarEvent.promoters.removeWhere((p) => p.remoteId == promoterId);
        await isarEvent.promoters.save();
      });
    }
  }

  /// Updates the promoters associated with an event on Supabase and updates the local cache.
  Future<void> updateEventPromoters(int eventId, List<int> promoterIds) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to update event promoters.");
    }
    // Delete existing entries on Supabase.
    await _supabase.from('event_promoter').delete().eq('event_id', eventId);
    final entries = promoterIds
        .map((promoterId) => {
              'event_id': eventId,
              'promoter_id': promoterId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('event_promoter').insert(entries).select();
      if ((response as List).isEmpty) {
        throw Exception("Failed to update event promoters.");
      }
      // Update local cache.
      final isar = await _isarFuture;
      final isarEvent =
          await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
      if (isarEvent != null) {
        await _updateEventPromotersCache(isarEvent, promoterIds, isar);
      }
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE (Event Promoter Links)
  // --------------------------------------------------------------------------

  /// Factorized helper to update the promoter links in a cached event.
  Future<void> _updateEventPromotersCache(
      IsarEvent isarEvent, List<int> promoterIds, Isar isar) async {
    await isar.writeTxn(() async {
      isarEvent.promoters.clear();
      for (final id in promoterIds) {
        final isarPromoter =
            await isar.isarPromoters.filter().remoteIdEqualTo(id).findFirst();
        if (isarPromoter != null) {
          isarEvent.promoters.add(isarPromoter);
        }
      }
      await isarEvent.promoters.save();
    });
  }

  /// Factorized helper to add a promoter link to a cached event.
  Future<void> _storePromoterInEventCache(
      IsarEvent isarEvent, int promoterId, Isar isar) async {
    await isar.writeTxn(() async {
      await isarEvent.promoters.load();
      if (!isarEvent.promoters.any((p) => p.remoteId == promoterId)) {
        final isarPromoter = await isar.isarPromoters
            .filter()
            .remoteIdEqualTo(promoterId)
            .findFirst();
        if (isarPromoter != null) {
          isarEvent.promoters.add(isarPromoter);
        }
      }
      await isarEvent.promoters.save();
    });
  }

  /// Helper function to load the cached promoters for an event.
  Future<List<Promoter>> _loadCachedPromoters(int eventId, Isar isar) async {
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent != null) {
      await isarEvent.promoters.load();
      final cachedIds = isarEvent.promoters.map((p) => p.remoteId).toList();
      return await _promoterService.getPromotersByIds(cachedIds);
    }
    return [];
  }
}
