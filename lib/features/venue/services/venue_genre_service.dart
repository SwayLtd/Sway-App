// lib/features/venue/services/venue_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class VenueGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<int>> getGenresByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_genre')
        .select('genre_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    return response.map<int>((entry) => entry['genre_id'] as int).toList();
  }

  Future<void> updateVenueGenres(int venueId, List<int> genres) async {
    // Supprimer les genres existants
    await _supabase.from('venue_genre').delete().eq('venue_id', venueId);

    // Ajouter les nouveaux genres
    final entries = genres
        .map((genreId) => {
              'venue_id': venueId,
              'genre_id': genreId,
            })
        .toList();

    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('venue_genre').insert(entries).select();

      if (response.isEmpty) {
        throw Exception('Failed to update venue genres.');
      }
    }
  }
}
