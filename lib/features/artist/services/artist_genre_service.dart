// lib/features/artist/services/artist_genre_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/artist/models/isar_artist.dart';
import 'package:sway/features/genre/models/isar_genre.dart';

class ArtistGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves the genre IDs associated with an artist.
  /// - Online: fetches from Supabase and updates the local cache (Artist.genres link).
  /// - Offline: returns genre IDs from the cached IsarArtist.
  Future<List<int>> getGenresByArtistId(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response = await _supabase
          .from('artist_genre')
          .select('genre_id')
          .eq('artist_id', artistId);
      if ((response as List).isEmpty) return [];
      final genreIds =
          response.map<int>((entry) => entry['genre_id'] as int).toList();

      // Update local cache for the artist.
      final isarArtist =
          await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
      if (isarArtist != null) {
        await _updateArtistGenresCache(isarArtist, genreIds, isar);
      }
      return genreIds;
    } else {
      final isarArtist =
          await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
      if (isarArtist != null) {
        await isarArtist.genres.load();
        return isarArtist.genres.map((g) => g.remoteId).toList();
      }
      return [];
    }
  }

  /// Adds a genre to an artist.
  Future<void> addGenreToArtist(int artistId, int genreId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to add genre to artist.");
    }
    // Check if genre already exists
    final existingGenres = await getGenresByArtistId(artistId);
    if (existingGenres.contains(genreId)) return;

    final response = await _supabase.from('artist_genre').insert({
      'artist_id': artistId,
      'genre_id': genreId,
    }).select();

    if ((response as List).isEmpty) {
      throw Exception('Failed to add genre to artist.');
    }

    // Update local cache.
    final isar = await _isarFuture;
    final isarArtist =
        await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
    if (isarArtist != null) {
      await _storeGenreInArtistCache(isarArtist, genreId, isar);
    }
  }

  /// Removes a genre from an artist.
  Future<void> removeGenreFromArtist(int artistId, int genreId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to remove genre from artist.");
    }
    final response = await _supabase
        .from('artist_genre')
        .delete()
        .eq('artist_id', artistId)
        .eq('genre_id', genreId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to remove genre from artist.');
    }
    // Update local cache.
    final isar = await _isarFuture;
    final isarArtist =
        await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
    if (isarArtist != null) {
      await isar.writeTxn(() async {
        await isarArtist.genres.load();
        isarArtist.genres.removeWhere((g) => g.remoteId == genreId);
        await isarArtist.genres.save();
      });
    }
  }

  /// Updates the genres associated with an artist.
  Future<void> updateArtistGenres(int artistId, List<int> genres) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to update artist genres.");
    }
    // Delete existing records on Supabase.
    await _supabase.from('artist_genre').delete().eq('artist_id', artistId);
    final uniqueGenres = genres.toSet().toList();
    final entries = uniqueGenres
        .map((genreId) => {
              'artist_id': artistId,
              'genre_id': genreId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response = await _supabase
          .from('artist_genre')
          .upsert(entries, onConflict: 'genre_id')
          .select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update artist genres.');
      }
      // Update local cache.
      final isar = await _isarFuture;
      final isarArtist =
          await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
      if (isarArtist != null) {
        await _updateArtistGenresCache(isarArtist, uniqueGenres, isar);
      }
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE (Artist Genre Links)
  // --------------------------------------------------------------------------

  /// Factorized helper to update the genre links in a cached artist.
  Future<void> _updateArtistGenresCache(
      IsarArtist isarArtist, List<int> genreIds, Isar isar) async {
    await isar.writeTxn(() async {
      isarArtist.genres.clear();
      for (final id in genreIds) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(id).findFirst();
        if (isarGenre != null) {
          isarArtist.genres.add(isarGenre);
        }
      }
      await isarArtist.genres.save();
    });
  }

  /// Factorized helper to add a genre link to a cached artist.
  Future<void> _storeGenreInArtistCache(
      IsarArtist isarArtist, int genreId, Isar isar) async {
    await isar.writeTxn(() async {
      await isarArtist.genres.load();
      if (!isarArtist.genres.any((g) => g.remoteId == genreId)) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(genreId).findFirst();
        if (isarGenre != null) {
          isarArtist.genres.add(isarGenre);
        }
      }
      await isarArtist.genres.save();
    });
  }
}
