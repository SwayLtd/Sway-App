// lib/features/user/services/user_follow_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur suit un genree spécifique
  Future<bool> isFollowingGenre(int genreId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_follow_genre')
        .select()
        .eq('user_id', userId)
        .eq('genre_id', genreId)
        .single();

    return response.isNotEmpty;
  }

  /// Suit un genree
  Future<void> followGenre(int genreId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase.from('user_follow_genre').insert({
      'user_id': userId,
      'genre_id': genreId,
    });
  }

  /// Ne suit plus un genree
  Future<void> unfollowGenre(int genreId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase
        .from('user_follow_genre')
        .delete()
        .eq('user_id', userId)
        .eq('genre_id', genreId);
  }

  /// Récupère le nombre de followers d'un genree
  Future<int> getGenreFollowersCount(int genreId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select('user_id')
        .eq('genre_id', genreId)
        .single();

    return response.length;
  }

  /// Récupère les genrees suivis par un utilisateur spécifique
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

  /// Récupère les utilisateurs qui suivent un genree spécifique
  Future<List<AppUser.User>> getFollowersForGenre(int genreId) async {
    final response = await _supabase
        .from('user_follow_genre')
        .select('user_id')
        .eq('genre_id', genreId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(followerIds);
  }
}
