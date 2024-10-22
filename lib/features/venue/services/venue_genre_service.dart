// lib/features/venue/services/venue_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class VenueGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<int>> getGenresByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_genres')
        .select('genre_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    return response.map((entry) => entry['genre_id'] as int).toList();
  }

  Future<List<int>> getVenuesByGenreId(int genreId) async {
    final response = await _supabase
        .from('venue_genres')
        .select('venue_id')
        .eq('genre_id', genreId);

    if (response.isEmpty) {
      return [];
    }

    return response.map((entry) => entry['venue_id'] as int).toList();
  }

  Future<void> addGenreToVenue(int venueId, int genreId) async {
    final response = await _supabase.from('venue_genres').insert({
      'venue_id': venueId,
      'genre_id': genreId,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add genre to venue.');
    }
  }

  Future<void> removeGenreFromVenue(int venueId, int genreId) async {
    final response = await _supabase
        .from('venue_genres')
        .delete()
        .eq('venue_id', venueId)
        .eq('genre_id', genreId);

    if (response.isEmpty) {
      throw Exception('Failed to remove genre from venue.');
    }
  }
}
