// lib/features/user/services/user_follow_user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowUserService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur suit un autre utilisateur spécifique
  Future<bool> isFollowingUser(int targetUserId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final response = await _supabase
        .from('user_follow_user')
        .select()
        .eq('follower_id', userId)
        .eq('followed_id', targetUserId);

    return response.isNotEmpty;
  }

  /// Suit un utilisateur
  Future<void> followUser(int targetUserId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    await _supabase.from('user_follow_user').insert({
      'follower_id': userId,
      'followed_id': targetUserId,
    }).select();
  }

  /// Ne suit plus un utilisateur
  Future<void> unfollowUser(int targetUserId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    await _supabase
        .from('user_follow_user')
        .delete()
        .eq('follower_id', userId)
        .eq('followed_id', targetUserId)
        .select();
  }

  /// Récupère le nombre de followers d'un utilisateur
  Future<int> getFollowersCount(int targetUserId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('follower_id')
        .eq('followed_id', targetUserId)
        .single();

    return response.length;
  }

  /// Récupère le nombre de suivis d'un utilisateur
  Future<int> getFollowingCount(int userId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('followed_id')
        .eq('follower_id', userId)
        .single();

    return response.length;
  }

  /// Récupère les utilisateurs qui suivent un utilisateur spécifique
  Future<List<AppUser.User>> getFollowersForUser(int targetUserId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('follower_id')
        .eq('followed_id', targetUserId);

    final List<int> followerIds =
        response.map((item) => item['follower_id'] as int).toList();

    return await _userService.getUsersByIds(followerIds);
  }

  /// Récupère les utilisateurs que l'utilisateur actuellement connecté suit
  Future<List<AppUser.User>> getFollowingForCurrentUser() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final response = await _supabase
        .from('user_follow_user')
        .select('followed_id')
        .eq('follower_id', userId);

    final List<int> followingIds =
        response.map((item) => item['followed_id'] as int).toList();

    return await _userService.getUsersByIds(followingIds);
  }
}
