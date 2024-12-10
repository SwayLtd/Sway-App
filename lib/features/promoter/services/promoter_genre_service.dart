// lib/features/promoter/services/promoter_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class PromoterGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Récupère les genres associés à un promoteur.
  Future<List<int>> getGenresByPromoterId(int promoterId) async {
    final response = await _supabase
        .from('promoter_genre')
        .select('genre_id')
        .eq('promoter_id', promoterId);

    if (response.isEmpty) {
      return [];
    }

    return response.map<int>((entry) => entry['genre_id'] as int).toList();
  }

  /// Récupère les promoteurs associés à un genre.
  Future<List<int>> getPromotersByGenreId(int genreId) async {
    final response = await _supabase
        .from('promoter_genre')
        .select('promoter_id')
        .eq('genre_id', genreId);

    if (response.isEmpty) {
      return [];
    }

    return response.map<int>((entry) => entry['promoter_id'] as int).toList();
  }

  /// Ajoute un genre à un promoteur.
  Future<void> addGenreToPromoter(int promoterId, int genreId) async {
    final response = await _supabase.from('promoter_genre').insert({
      'promoter_id': promoterId,
      'genre_id': genreId,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add genre to promoter.');
    }
  }

  /// Supprime un genre d'un promoteur.
  Future<void> removeGenreFromPromoter(int promoterId, int genreId) async {
    final response = await _supabase
        .from('promoter_genre')
        .delete()
        .eq('promoter_id', promoterId)
        .eq('genre_id', genreId);

    if (response.isEmpty) {
      throw Exception('Failed to remove genre from promoter.');
    }
  }

  /// Met à jour les genres associés à un promoteur.
  Future<void> updatePromoterGenres(int promoterId, List<int> genres) async {
    // Supprimer les genres existants
    await _supabase
        .from('promoter_genre')
        .delete()
        .eq('promoter_id', promoterId);

    // Ajouter les nouveaux genres
    final entries = genres
        .map((genreId) => {
              'promoter_id': promoterId,
              'genre_id': genreId,
            })
        .toList();

    if (entries.isNotEmpty) {
      final response = await _supabase.from('promoter_genre').insert(entries);
      if (response.isEmpty) {
        throw Exception('Failed to update promoter genres.');
      }
    }
  }
}
