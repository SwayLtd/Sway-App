// user_follow_promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowPromoterService {
  final _supabase = Supabase.instance.client;
  final int userId = 3;

  Future<bool> isFollowingPromoter(int promoterId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select()
        .eq('user_id', userId)
        .eq('promoter_id', promoterId);

    return response.isNotEmpty;
  }

  Future<void> followPromoter(int promoterId) async {
    await _supabase.from('user_follow_promoter').insert({
      'user_id': userId,
      'promoter_id': promoterId,
    });
  }

  Future<void> unfollowPromoter(int promoterId) async {
    await _supabase
        .from('user_follow_promoter')
        .delete()
        .eq('user_id', userId)
        .eq('promoter_id', promoterId);
  }

  Future<int> getPromoterFollowersCount(int promoterId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('user_id')
        .eq('promoter_id', promoterId);

    return response.length;
  }

  Future<List<Promoter>> getFollowedPromotersByUserId(int userId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('promoter_id')
        .eq('user_id', userId);

    final List<int> followedPromoterIds =
        response.map((item) => item['promoter_id'] as int).toList();

    final List<Promoter> allPromoters = await PromoterService().getPromoters();

    return allPromoters
        .where((promoter) => followedPromoterIds.contains(promoter.id))
        .toList();
  }

  Future<List<AppUser.User>> getFollowersForPromoter(int promoterId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('user_id')
        .eq('promoter_id', promoterId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
