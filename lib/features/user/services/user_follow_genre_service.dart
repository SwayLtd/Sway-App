// lib/features/user/services/user_follow_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isFollowingGenre(int genreId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_follow_genre')
          .select()
          .eq('user_id', userId)
          .eq('genre_id', genreId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status for genre $genreId: $e');
      return false;
    }
  }

  Future<void> followGenre(int genreId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_follow_genre').insert({
        'user_id': userId,
        'genre_id': genreId,
      });
    } catch (e) {
      print('Error following genre $genreId: $e');
    }
  }

  Future<void> unfollowGenre(int genreId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('user_follow_genre')
          .delete()
          .eq('user_id', userId)
          .eq('genre_id', genreId);
    } catch (e) {
      print('Error unfollowing genre $genreId: $e');
    }
  }

  Future<int> getGenreFollowersCount(int genreId) async {
    try {
      final response = await _supabase
          .from('user_follow_genre')
          .select('user_id')
          .eq('genre_id', genreId);

      return response.length;
    } catch (e) {
      print('Error getting followers count for genre $genreId: $e');
      return 0;
    }
  }

  Future<List<Genre>> getFollowedGenresByUserId(int userId) async {
    try {
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
    } catch (e) {
      print('Error getting followed genres for user $userId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getFollowersForGenre(int genreId) async {
    try {
      final response = await _supabase
          .from('user_follow_genre')
          .select('user_id')
          .eq('genre_id', genreId);

      final List<int> followerIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(followerIds);
    } catch (e) {
      print('Error getting followers for genre $genreId: $e');
      return [];
    }
  }
}
