import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';

class GenreService {
  Future<List<Genre>> getGenres() async {
    final String response = await rootBundle.loadString('assets/databases/genres.json');
    final List<dynamic> genreJson = json.decode(response) as List<dynamic>;
    return genreJson.map((json) => Genre.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Genre?> getGenreById(String genreId) async {
    final List<Genre> genres = await getGenres();
    try {
      final Genre genre = genres.firstWhere((genre) => genre.id == genreId);
      return genre;
    } catch (e) {
      return null;
    }
  }
}
