// genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';

class GenreService {
  final _supabase = Supabase.instance.client;

  Future<List<Genre>> searchGenres(String query) async {
    final response = await _supabase
        .from('genres')
        .select()
        .ilike('name', '%$query%');

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
    final response = await _supabase
        .from('genres')
        .select()
        .eq('id', genreId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Genre.fromJson(response);
  }
}
