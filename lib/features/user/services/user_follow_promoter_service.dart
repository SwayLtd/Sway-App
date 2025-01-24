// lib/features/user/services/user_follow_promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowPromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur suit un promotere spécifique
  Future<bool> isFollowingPromoter(int promoterId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_follow_promoter')
        .select()
        .eq('user_id', userId)
        .eq('promoter_id', promoterId);

    return response.isNotEmpty;
  }

  /// Suit un promotere
  Future<void> followPromoter(int promoterId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase.from('user_follow_promoter').insert({
      'user_id': userId,
      'promoter_id': promoterId,
    });
  }

  /// Ne suit plus un promotere
  Future<void> unfollowPromoter(int promoterId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase
        .from('user_follow_promoter')
        .delete()
        .eq('user_id', userId)
        .eq('promoter_id', promoterId);
  }

  /// Récupère le nombre de followers d'un promotere
  Future<int> getPromoterFollowersCount(int promoterId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('user_id')
        .eq('promoter_id', promoterId);

    return response.length;
  }

  /// Récupère les promoteres suivis par un utilisateur spécifique
  Future<List<Promoter>> getFollowedPromotersByUserId(int userId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('promoter_id')
        .eq('user_id', userId);

    final List<int> followedPromoterIds =
        response.map((item) => item['promoter_id'] as int).toList();

    final List<Promoter> allPromoters = await PromoterService().getPromoters();

    return allPromoters
        .where((promoter) => followedPromoterIds.contains(promoter.id!))
        .toList();
  }

  /// Récupère les utilisateurs qui suivent un promotere spécifique
  Future<List<AppUser.User>> getFollowersForPromoter(int promoterId) async {
    final response = await _supabase
        .from('user_follow_promoter')
        .select('user_id')
        .eq('promoter_id', promoterId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(followerIds);
  }
}
