// lib/features/promoter/services/promoter_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/genre/models/isar_genre.dart';
import 'package:sway/features/promoter/models/isar_promoter.dart';

class PromoterGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves the genre IDs associated with a promoter.
  /// - Online: fetches from Supabase, updates the local cache and returns genre IDs.
  /// - Offline: returns genre IDs from the local cache.
  Future<List<int>> getGenresByPromoterId(int promoterId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('promoter_genre')
          .select('genre_id')
          .eq('promoter_id', promoterId);
      if ((response as List).isEmpty) return [];
      final genreIds =
          response.map<int>((entry) => entry['genre_id'] as int).toList();

      // Update local cache for the promoter.
      final isarPromoter = await isar.isarPromoters
          .filter()
          .remoteIdEqualTo(promoterId)
          .findFirst();
      if (isarPromoter != null) {
        await _updatePromoterGenresCache(isarPromoter, genreIds, isar);
      }
      return genreIds;
    } else {
      // Offline: use the factorized load from cache.
      return await _loadPromoterGenresFromCache(isar, promoterId);
    }
  }

  /// Adds a genre to a promoter.
  Future<void> addGenreToPromoter(int promoterId, int genreId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to add genre to promoter.');
    }
    final response = await _supabase.from('promoter_genre').insert({
      'promoter_id': promoterId,
      'genre_id': genreId,
    }).select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to add genre to promoter.');
    }
    final isar = await _isarFuture;
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await _storeGenreInPromoterCache(isarPromoter, genreId, isar);
    }
  }

  /// Removes a genre from a promoter.
  Future<void> removeGenreFromPromoter(int promoterId, int genreId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to remove genre from promoter.');
    }
    final response = await _supabase
        .from('promoter_genre')
        .delete()
        .eq('promoter_id', promoterId)
        .eq('genre_id', genreId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to remove genre from promoter.');
    }
    final isar = await _isarFuture;
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await isar.writeTxn(() async {
        await isarPromoter.genres.load();
        isarPromoter.genres.removeWhere((g) => g.remoteId == genreId);
        await isarPromoter.genres.save();
      });
    }
  }

  /// Updates the genres associated with a promoter.
  Future<void> updatePromoterGenres(int promoterId, List<int> genres) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to update promoter genres.');
    }
    await _supabase
        .from('promoter_genre')
        .delete()
        .eq('promoter_id', promoterId);
    final entries = genres
        .map((genreId) => {
              'promoter_id': promoterId,
              'genre_id': genreId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('promoter_genre').insert(entries).select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update promoter genres.');
      }
      final isar = await _isarFuture;
      final isarPromoter = await isar.isarPromoters
          .filter()
          .remoteIdEqualTo(promoterId)
          .findFirst();
      if (isarPromoter != null) {
        await _updatePromoterGenresCache(isarPromoter, genres, isar);
      }
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE
  // --------------------------------------------------------------------------

  /// Factorized helper to update the genre links in a cached promoter.
  Future<void> _updatePromoterGenresCache(
      IsarPromoter isarPromoter, List<int> genreIds, Isar isar) async {
    await isar.writeTxn(() async {
      isarPromoter.genres.clear();
      for (final id in genreIds) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(id).findFirst();
        if (isarGenre != null) {
          isarPromoter.genres.add(isarGenre);
        }
      }
      await isarPromoter.genres.save();
    });
    // print("Cache updated for promoterId ${isarPromoter.remoteId}: " + "genres in cache: ${isarPromoter.genres.map((g) => g.remoteId).toList()}");
  }

  /// Factorized helper to add a genre link to a cached promoter.
  Future<void> _storeGenreInPromoterCache(
      IsarPromoter isarPromoter, int genreId, Isar isar) async {
    await isar.writeTxn(() async {
      await isarPromoter.genres.load();
      if (!isarPromoter.genres.any((g) => g.remoteId == genreId)) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(genreId).findFirst();
        if (isarGenre != null) {
          isarPromoter.genres.add(isarGenre);
        }
      }
      await isarPromoter.genres.save();
    });
    // print("Stored genreId $genreId in cache for promoterId ${isarPromoter.remoteId}");
  }

  /// Factorized helper to load the genre IDs from the cache for a given promoter.
  Future<List<int>> _loadPromoterGenresFromCache(
      Isar isar, int promoterId) async {
    final isarPromoter = await isar.isarPromoters
        .filter()
        .remoteIdEqualTo(promoterId)
        .findFirst();
    if (isarPromoter != null) {
      await isarPromoter.genres.load();
      final loadedIds = isarPromoter.genres.map((g) => g.remoteId).toList();
      // print("Loaded genres from cache for promoterId $promoterId: $loadedIds");
      return loadedIds;
    }
    return [];
  }
}
