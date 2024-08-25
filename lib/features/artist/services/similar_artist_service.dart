import 'package:supabase_flutter/supabase_flutter.dart';

class SimilarArtistService {
  final _supabase = Supabase.instance.client;

  Future<List<int>> getSimilarArtistsByArtistId(int artistId) async {
    final response = await _supabase
        .from('similar_artists')
        .select('similar_artist_id')
        .eq('artist_id', artistId);

    if (response.isEmpty) {
      return [];
    }

    return response.map<int>((entry) => entry['similar_artist_id'] as int).toList();
  }
}
