// lib/features/artist/services/artist_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retrieves the genres associated with an artist.
  Future<List<int>> getGenresByArtistId(int artistId) async {
    final response = await _supabase
        .from('artist_genre')
        .select('genre_id')
        .eq('artist_id', artistId);

    if (response.isEmpty) {
      return [];
    }

    return response.map<int>((entry) => entry['genre_id'] as int).toList();
  }

  /// Adds a genre to an artist.
  /// This method checks if the genre is already associated to avoid duplicate entries.
  Future<void> addGenreToArtist(int artistId, int genreId) async {
    final existingGenres = await getGenresByArtistId(artistId);
    if (existingGenres.contains(genreId)) {
      // Genre already exists for this artist; do nothing.
      return;
    }

    final response = await _supabase.from('artist_genre').insert({
      'artist_id': artistId,
      'genre_id': genreId,
    }).select();

    if (response.isEmpty) {
      throw Exception('Failed to add genre to artist.');
    }
  }

  /// Removes a genre from an artist.
  Future<void> removeGenreFromArtist(int artistId, int genreId) async {
    final response = await _supabase
        .from('artist_genre')
        .delete()
        .eq('artist_id', artistId)
        .eq('genre_id', genreId)
        .select();

    if (response.isEmpty) {
      throw Exception('Failed to remove genre from artist.');
    }
  }

  /// Updates the genres associated with an artist.
  Future<void> updateArtistGenres(int artistId, List<int> genres) async {
    // Delete the existing genres for the artist.
    await _supabase.from('artist_genre').delete().eq('artist_id', artistId);

    // Deduplicate the list of genres.
    final uniqueGenres = genres.toSet().toList();

    // Prepare the entries for insertion.
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

      if (response.isEmpty) {
        throw Exception('Failed to update artist genres.');
      }
    }
  }
}
