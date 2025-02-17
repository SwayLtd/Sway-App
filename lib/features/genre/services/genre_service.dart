// genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/genre/models/genre_model.dart';

class GenreService {
  final _supabase = Supabase.instance.client;

  Future<List<Genre>> searchGenres(String query) async {
    final response =
        await _supabase.from('genres').select().ilike('name', '%$query%');

    if (response.isEmpty) {
      print('No genres found.');
      // throw Exception('No genres found.');
    }

    return response.map<Genre>((json) => Genre.fromJson(json)).toList();
  }

  Future<List<Genre>> getGenres() async {
    final response = await _supabase.from('genres').select();

    if (response.isEmpty) {
      throw Exception('No genres found.');
    }

    return response.map<Genre>((json) => Genre.fromJson(json)).toList();
  }

  Future<Genre?> getGenreById(int genreId) async {
    final response =
        await _supabase.from('genres').select().eq('id', genreId).maybeSingle();

    if (response == null) {
      return null;
    }

    return Genre.fromJson(response);
  }

  Future<List<Genre>> getRecommendedGenres({int? userId, int limit = 5}) async {
    try {
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };

      final response =
          await _supabase.rpc('get_recommended_genres', params: params);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return (response)
          .map<Genre>((json) => Genre.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching recommended genres: $e');
      throw e;
    }
  }
}
