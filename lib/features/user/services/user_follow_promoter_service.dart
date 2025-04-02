// lib/features/user/services/user_follow_promoter_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowPromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isFollowingPromoter(int promoterId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_follow_promoter')
          .select()
          .eq('user_id', userId)
          .eq('promoter_id', promoterId);

      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking follow status for promoter $promoterId: $e');
      return false;
    }
  }

  Future<void> followPromoter(int promoterId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_follow_promoter').insert({
        'user_id': userId,
        'promoter_id': promoterId,
      });
    } catch (e) {
      debugPrint('Error following promoter $promoterId: $e');
    }
  }

  Future<void> unfollowPromoter(int promoterId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('user_follow_promoter')
          .delete()
          .eq('user_id', userId)
          .eq('promoter_id', promoterId);
    } catch (e) {
      debugPrint('Error unfollowing promoter $promoterId: $e');
    }
  }

  Future<int> getPromoterFollowersCount(int promoterId) async {
    try {
      final response = await _supabase
          .from('user_follow_promoter')
          .select('user_id')
          .eq('promoter_id', promoterId);

      return response.length;
    } catch (e) {
      debugPrint('Error getting followers count for promoter $promoterId: $e');
      return 0;
    }
  }

  Future<List<Promoter>> getFollowedPromotersByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('user_follow_promoter')
          .select('promoter_id')
          .eq('user_id', userId);

      final List<int> followedPromoterIds =
          response.map((item) => item['promoter_id'] as int).toList();

      final List<Promoter> allPromoters =
          await PromoterService().getPromoters();

      return allPromoters
          .where((promoter) => followedPromoterIds.contains(promoter.id!))
          .toList();
    } catch (e) {
      debugPrint('Error getting followed promoters for user $userId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getFollowersForPromoter(int promoterId) async {
    try {
      final response = await _supabase
          .from('user_follow_promoter')
          .select('user_id')
          .eq('promoter_id', promoterId);

      final List<int> followerIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(followerIds);
    } catch (e) {
      debugPrint('Error getting followers for promoter $promoterId: $e');
      return [];
    }
  }
}
