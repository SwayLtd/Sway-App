// lib/features/artist/services/artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';

class ArtistService {
  final _supabase = Supabase.instance.client;

  Future<List<Artist>> searchArtists(String query) async {
    final response = await _supabase
        .from('artists')
        .select()
        .ilike('name', '%$query%');

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  Future<List<Artist>> getArtists() async {
    final response = await _supabase.from('artists').select();

    if (response.isEmpty) {
      throw Exception('No artists found.');
    }

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  Future<Artist?> getArtistById(int artistId) async {
    final response = await _supabase
        .from('artists')
        .select()
        .eq('id', artistId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Artist.fromJson(response);
  }

  Future<List<Artist>> getTopArtistsByGenreId(int genreId) async {
    // Récupérer les relations artist-genre
    final artistGenreResponse = await _supabase
        .from('artist_genre')
        .select('artist_id')
        .eq('genre_id', genreId);

    if (artistGenreResponse.isEmpty) {
      return [];
    }

    final artistIds = artistGenreResponse.map<int>((entry) => entry['artist_id'] as int).toList();

    if (artistIds.isEmpty) {
      return [];
    }

    // Construire un filtre "OR" pour obtenir les artistes par leurs IDs
    final filter = artistIds.map((id) => 'id.eq.$id').join(',');

    final response = await _supabase
        .from('artists')
        .select()
        .or(filter);

    if (response.isEmpty) {
      return [];
    }

    final artists = response.map<Artist>((json) => Artist.fromJson(json)).toList();

    // Trier les artistes par nombre de followers
    artists.sort((a, b) => b.followers.compareTo(a.followers));

    return artists;
  }

  Future<List<Artist>> getArtistsByIds(List<int> artistIds) async {
    if (artistIds.isEmpty) {
      return [];
    }

    // Construire une chaîne de filtres 'or' pour chaque ID
    final String orFilter = artistIds.map((id) => 'id.eq.$id').join(',');

    final response = await _supabase
        .from('artists')
        .select()
        .or(orFilter); // Utilisation de .or() au lieu de .filter()

    if (response.isEmpty) {
      return [];
    }

    return response
        .map<Artist>((json) => Artist.fromJson(json))
        .toList();
  }
}
