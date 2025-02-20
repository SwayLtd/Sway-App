// lib/features/artist/services/similar_artist_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';

class SimilarArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retrieves the IDs of similar artists for a given artist.
  /// Checks connectivity: if offline, vous pouvez envisager d'ajouter une version en cache.
  Future<List<int>> getSimilarArtistsByArtistId(int artistId) async {
    final online = await isConnected();
    if (online) {
      final response = await _supabase
          .from('similar_artists')
          .select('similar_artist_id')
          .eq('artist_id', artistId);
      if ((response as List).isEmpty) return [];
      return response
          .map<int>((entry) => entry['similar_artist_id'] as int)
          .toList();
    } else {
      // Pour l'instant, en mode hors ligne, nous renvoyons une liste vide.
      // Vous pouvez implémenter une version en cache similaire aux autres services si besoin.
      return [];
    }
  }
}
