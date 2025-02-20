// lib/features/user/services/user_follow_user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowUserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isFollowingUser(int targetUserId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_follow_user')
          .select()
          .eq('follower_id', userId)
          .eq('followed_id', targetUserId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status for user $targetUserId: $e');
      return false;
    }
  }

  Future<void> followUser(int targetUserId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_follow_user').insert({
        'follower_id': userId,
        'followed_id': targetUserId,
      });
    } catch (e) {
      print('Error following user $targetUserId: $e');
    }
  }

  Future<void> unfollowUser(int targetUserId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('user_follow_user')
          .delete()
          .eq('follower_id', userId)
          .eq('followed_id', targetUserId);
    } catch (e) {
      print('Error unfollowing user $targetUserId: $e');
    }
  }

  Future<int> getFollowersCount(int targetUserId) async {
  try {
    final response = await _supabase
        .from('user_follow_user')
        .select('follower_id') // Assurez-vous de ne pas ajouter .single() ici
        .eq('followed_id', targetUserId);

    // On s'assure que response est bien une liste
    return response.length;
  } catch (e) {
    print('Error getting followers count for user $targetUserId: $e');
    return 0;
  }
}


  Future<int> getFollowingCount(int userId) async {
    try {
      final response = await _supabase
          .from('user_follow_user')
          .select('followed_id')
          .eq('follower_id', userId);

      return response.length;
    } catch (e) {
      print('Error getting following count for user $userId: $e');
      return 0;
    }
  }

  Future<List<AppUser.User>> getFollowersForUser(int targetUserId) async {
    try {
      final response = await _supabase
          .from('user_follow_user')
          .select('follower_id')
          .eq('followed_id', targetUserId);

      final List<int> followerIds =
          response.map((item) => item['follower_id'] as int).toList();

      return await _userService.getUsersByIds(followerIds);
    } catch (e) {
      print('Error getting followers for user $targetUserId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getFollowingForCurrentUser() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return [];

      final response = await _supabase
          .from('user_follow_user')
          .select('followed_id')
          .eq('follower_id', userId);

      final List<int> followingIds =
          response.map((item) => item['followed_id'] as int).toList();

      return await _userService.getUsersByIds(followingIds);
    } catch (e) {
      print('Error getting following list for current user: $e');
      return [];
    }
  }
}

