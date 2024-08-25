import 'package:supabase_flutter/supabase_flutter.dart';

class ArtistGenreService {
  final _supabase = Supabase.instance.client;

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
}
