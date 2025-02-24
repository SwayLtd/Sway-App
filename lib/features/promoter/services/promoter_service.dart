// lib/features/promoter/services/promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';

// Import the regular Promoter model used for API exchange and UI
import 'package:sway/features/promoter/models/promoter_model.dart';
// Import the Isar Promoter model
import 'package:sway/features/promoter/models/isar_promoter.dart';

class PromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  Future<List<Promoter>> getPromoters() async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      // Online: fetch promoters from Supabase
      final response = await _supabase.from('promoters').select();
      if ((response as List).isEmpty) {
        // Si la réponse est vide, on tente de charger depuis le cache.
        return await _loadAllPromotersFromIsar(isar);
      }
      final promoters = response
          .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
          .toList();
      // Met à jour le cache avec les données fraîchement récupérées
      for (final promoter in promoters) {
        await _storePromoterInIsar(isar, promoter);
      }
      return promoters;
    } else {
      // Offline: load promoters from the local cache
      return await _loadAllPromotersFromIsar(isar);
    }
  }

  Future<Promoter?> getPromoterById(int id) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      // Online: try to fetch the promoter from Supabase.
      final response =
          await _supabase.from('promoters').select().eq('id', id).maybeSingle();
      if (response != null) {
        final promoter = Promoter.fromJsonWithoutEvents(response);
        await _storePromoterInIsar(isar, promoter);
        return promoter;
      } else {
        // If not found online, fall back to cache.
        return await _loadPromoterFromIsar(id, isar: isar);
      }
    } else {
      // Offline: load promoter from the local cache.
      return await _loadPromoterFromIsar(id, isar: isar);
    }
  }

  /// Returns promoters by a list of promoter IDs.
  Future<List<Promoter>> getPromotersByIds(List<int> promoterIds) async {
    if (promoterIds.isEmpty) return [];
    final String ids = '(${promoterIds.join(',')})';
    final response =
        await _supabase.from('promoters').select().filter('id', 'in', ids);
    if ((response as List).isEmpty) return [];
    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  /// Searches for promoters by name.
  Future<List<Promoter>> searchPromoters(String query) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    final response =
        await _supabase.from('promoters').select().ilike('name', '%$query%');
    if ((response as List).isEmpty) return [];
    final promoters = response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
    if (online) {
      final isar = await _isarFuture;
      for (final promoter in promoters) {
        await _storePromoterInIsar(isar, promoter);
      }
    } else {
      // Offline: load all venues from local cache.
      return await _loadAllPromotersFromIsar(isar);
    }
    return promoters;
  }

  /// Returns recommended promoters by calling a Supabase RPC.
  Future<List<Promoter>> getRecommendedPromoters(
      {int? userId, int limit = 5}) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    final params = <String, dynamic>{
      'p_user_id': userId,
      'p_limit': limit,
    };

    try {
      final response =
          await _supabase.rpc('get_recommended_promoters', params: params);
      if (response == null || (response as List).isEmpty) return [];
      final promoters = (response)
          .map<Promoter>((json) =>
              Promoter.fromJsonWithoutEvents(json as Map<String, dynamic>))
          .toList();
      if (online) {
        // Stocker le cache pour chaque promoter
        for (final promoter in promoters) {
          await _storePromoterInIsar(isar, promoter);
        }
      }
      return promoters;
    } catch (e) {
      // En cas d'erreur, on retourne les données du cache
      return await _loadAllPromotersFromIsar(isar);
    }
  }

  /// Adds a new promoter to the server and stores it locally.
  Future<Promoter> addPromoter(Promoter promoter) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection to add promoter.");
    final promoterData = promoter.toJson();
    final response = await _supabase
        .from('promoters')
        .insert(promoterData)
        .select()
        .single();
    final newPromoter = Promoter.fromJsonWithoutEvents(response);
    final isar = await _isarFuture;
    await _storePromoterInIsar(isar, newPromoter);
    return newPromoter;
  }

  /// Updates an existing promoter on the server and updates the local cache.
  Future<Promoter> updatePromoter(Promoter promoter) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to update promoter.");
    }
    final response = await _supabase
        .from('promoters')
        .update(promoter.toJson())
        .eq('id', promoter.id!)
        .select()
        .single();
    final updatedPromoter = Promoter.fromJsonWithoutEvents(response);
    final isar = await _isarFuture;
    await _storePromoterInIsar(isar, updatedPromoter);
    return updatedPromoter;
  }

  /// Deletes a promoter by ID on the server and locally.
  Future<void> deletePromoter(int promoterId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response = await _supabase
          .from('promoters')
          .delete()
          .eq('id', promoterId)
          .select();
      if ((response as List).isEmpty) {
        throw Exception("Failed to delete promoter on server.");
      }
    }
    await isar.writeTxn(() async {
      await isar.isarPromoters.filter().remoteIdEqualTo(promoterId).deleteAll();
    });
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR PROMOTERS (Local Cache)
  // --------------------------------------------------------------------------

  /// Stores a Promoter in Isar.
  Future<void> _storePromoterInIsar(Isar isar, Promoter promoter) async {
    await isar.writeTxn(() async {
      final isarPromoter = IsarPromoter()
        ..remoteId = promoter.id ?? 0
        ..name = promoter.name
        ..imageUrl = promoter.imageUrl
        ..description = promoter.description
        ..isVerified = promoter.isVerified;
      // TODO: Add linking for residentArtists, genres, upcomingEvents if needed.
      await isar.isarPromoters.put(isarPromoter);
    });
  }

  /// Loads a single Promoter from Isar by remoteId.
  Future<Promoter?> _loadPromoterFromIsar(int promoterId,
      {required Isar isar}) async {
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter == null) return null;
    return Promoter.fromJsonWithoutEvents({
      'id': isarPromoter.remoteId,
      'name': isarPromoter.name,
      'image_url': isarPromoter.imageUrl,
      'description': isarPromoter.description,
      'is_verified': isarPromoter.isVerified,
    });
  }

  Future<List<Promoter>> _loadAllPromotersFromIsar(Isar isar) async {
    final isarPromoters = await isar.isarPromoters.where().findAll();
    return isarPromoters.map((isarPromoter) {
      return Promoter.fromJsonWithoutEvents({
        'id': isarPromoter.remoteId,
        'name': isarPromoter.name,
        'image_url': isarPromoter.imageUrl,
        'description': isarPromoter.description,
        'is_verified': isarPromoter.isVerified,
      });
    }).toList();
  }
}
