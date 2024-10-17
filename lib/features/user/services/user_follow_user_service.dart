// user_follow_user_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowUserService {
  final _supabase = Supabase.instance.client;
  final int userId = 3;

  Future<bool> isFollowingUser(int targetUserId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select()
        .eq('follower_id', userId)
        .eq('followed_id', targetUserId);

    return response.isNotEmpty;
  }

  Future<void> followUser(int targetUserId) async {
    await _supabase.from('user_follow_user').insert({
      'follower_id': userId,
      'followed_id': targetUserId,
    });
  }

  Future<void> unfollowUser(int targetUserId) async {
    await _supabase
        .from('user_follow_user')
        .delete()
        .eq('follower_id', userId)
        .eq('followed_id', targetUserId);
  }

  Future<int> getFollowersCount(int targetUserId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('follower_id')
        .eq('followed_id', targetUserId);

    return response.length;
  }

  Future<int> getFollowingCount(int userId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('followed_id')
        .eq('follower_id', userId);

    return response.length;
  }

  Future<List<AppUser.User>> getFollowersForUser(int targetUserId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('follower_id')
        .eq('followed_id', targetUserId);

    final List<int> followerIds =
        response.map((item) => item['follower_id'] as int).toList();

    return await UserService().getUsersByIds(followerIds);
  }

  Future<List<AppUser.User>> getFollowingForUser(int userId) async {
    final response = await _supabase
        .from('user_follow_user')
        .select('followed_id')
        .eq('follower_id', userId);

    final List<int> followingIds =
        response.map((item) => item['followed_id'] as int).toList();

    return await UserService().getUsersByIds(followingIds);
  }
}
