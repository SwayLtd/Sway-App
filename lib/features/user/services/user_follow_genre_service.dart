// user_follow_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowGenreService {
  final _supabase = Supabase.instance.client;
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingGenre(int genreId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select()
        .eq('user_id', userId)
        .eq('genre_id', genreId);

    return response.isNotEmpty;
  }

  Future<void> followGenre(int genreId) async {
    await _supabase.from('user_follow_genre').insert({
      'user_id': userId,
      'genre_id': genreId,
    });
  }

  Future<void> unfollowGenre(int genreId) async {
    await _supabase
        .from('user_follow_genre')
        .delete()
        .eq('user_id', userId)
        .eq('genre_id', genreId);
  }

  Future<int> getGenreFollowersCount(int genreId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select('user_id')
        .eq('genre_id', genreId);

    return response.length;
  }

  Future<List<Genre>> getFollowedGenresByUserId(int userId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select('genre_id')
        .eq('user_id', userId);

    final List<int> followedGenreIds =
        response.map((item) => item['genre_id'] as int).toList();

    final List<Genre> allGenres = await GenreService().getGenres();

    return allGenres
        .where((genre) => followedGenreIds.contains(genre.id))
        .toList();
  }

  Future<List<AppUser.User>> getUsersFollowingGenre(int genreId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select('user_id')
        .eq('genre_id', genreId);

    final List<int> userIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(userIds);
  }
}
