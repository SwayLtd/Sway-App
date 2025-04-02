import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';

// Import the regular Genre model used for API exchange and UI
import 'package:sway/features/genre/models/genre_model.dart';
// Import the Isar Genre model
import 'package:sway/features/genre/models/isar_genre.dart';

class GenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Searches for genres by name.
  Future<List<Genre>> searchGenres(String query) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response =
            await _supabase.from('genres').select().ilike('name', '%$query%');
        if ((response as List).isEmpty) return [];
        final genres =
            response.map<Genre>((json) => Genre.fromJson(json)).toList();
        for (final genre in genres) {
          await _storeGenreInIsar(isar, genre);
        }
        return genres;
      } catch (e) {
        // debugPrint('Error in searchGenres (online): $e');
        return [];
      }
    } else {
      // Offline: ici, vous pouvez implémenter une recherche dans le cache si nécessaire.
      final allGenres = await _loadAllGenresFromIsar(isar);
      return allGenres
          .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  /// Returns all genres from Supabase (online-first).
  Future<List<Genre>> getGenres() async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase.from('genres').select();
        if ((response as List).isEmpty) {
          return await _loadAllGenresFromIsar(isar);
        }
        final genres =
            response.map<Genre>((json) => Genre.fromJson(json)).toList();
        for (final genre in genres) {
          await _storeGenreInIsar(isar, genre);
        }
        return genres;
      } catch (e) {
        // debugPrint('Error in getGenres (online): $e');
        return await _loadAllGenresFromIsar(isar);
      }
    } else {
      return await _loadAllGenresFromIsar(isar);
    }
  }

  /// Returns a genre by ID using an offline-first approach.
  Future<Genre?> getGenreById(int genreId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase
            .from('genres')
            .select()
            .eq('id', genreId)
            .maybeSingle();
        if (response != null) {
          final genre = Genre.fromJson(response);

          await _storeGenreInIsar(isar, genre);

          return genre;
        } else {
          return await _loadGenreFromIsar(genreId, isar: isar);
        }
      } catch (e) {
        // debugPrint('Error in getGenreById (online): $e');
        return await _loadGenreFromIsar(genreId, isar: isar);
      }
    } else {
      return await _loadGenreFromIsar(genreId, isar: isar);
    }
  }

  /// Returns recommended genres by calling a Supabase RPC.
  Future<List<Genre>> getRecommendedGenres({int? userId, int limit = 5}) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final params = <String, dynamic>{
          'p_user_id': userId,
          'p_limit': limit,
        };
        final response =
            await _supabase.rpc('get_recommended_genres', params: params);
        if (response == null || (response as List).isEmpty) return [];
        final genres = (response)
            .map<Genre>((json) => Genre.fromJson(json as Map<String, dynamic>))
            .toList();
        for (final genre in genres) {
          await _storeGenreInIsar(isar, genre);
        }
        return genres;
      } catch (e) {
        // debugPrint('Error in getRecommendedGenres (online): $e');
        return await _loadAllGenresFromIsar(isar);
      }
    } else {
      return await _loadAllGenresFromIsar(isar);
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR GENRES (Local Cache)
  // --------------------------------------------------------------------------

  /// Factorized function to store a Genre in Isar.
  Future<void> _storeGenreInIsar(Isar isar, Genre genre) async {
    await isar.writeTxn(() async {
      final isarGenre = IsarGenre()
        ..remoteId = genre.id
        ..name = genre.name
        ..description = genre.description;
      await isar.isarGenres.put(isarGenre);
    });
  }

  /// Loads a single Genre from Isar by remoteId.
  Future<Genre?> _loadGenreFromIsar(int genreId, {required Isar isar}) async {
    final isarGenre =
        await isar.isarGenres.filter().remoteIdEqualTo(genreId).findFirst();
    if (isarGenre == null) return null;
    return Genre(
      id: isarGenre.remoteId,
      name: isarGenre.name,
      description: isarGenre.description,
    );
  }

  /// Loads all genres from Isar.
  Future<List<Genre>> _loadAllGenresFromIsar(Isar isar) async {
    final isarGenres = await isar.isarGenres.where().findAll();
    return isarGenres.map((isarGenre) {
      return Genre(
        id: isarGenre.remoteId,
        name: isarGenre.name,
        description: isarGenre.description,
      );
    }).toList();
  }
}
