// lib/features/user/services/user_follow_venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowVenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur suit un venuee spécifique
  Future<bool> isFollowingVenue(int venueId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_follow_venue')
        .select()
        .eq('user_id', userId)
        .eq('venue_id', venueId)
        .single();

    return response.isNotEmpty;
  }

  /// Suit un venuee
  Future<void> followVenue(int venueId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase.from('user_follow_venue').insert({
      'user_id': userId,
      'venue_id': venueId,
    });
  }

  /// Ne suit plus un venuee
  Future<void> unfollowVenue(int venueId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    await _supabase
        .from('user_follow_venue')
        .delete()
        .eq('user_id', userId)
        .eq('venue_id', venueId);
  }

  /// Récupère le nombre de followers d'un venuee
  Future<int> getVenueFollowersCount(int venueId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select('user_id')
        .eq('venue_id', venueId)
        .single();

    return response.length;
  }

  /// Récupère les venuees suivis par un utilisateur spécifique
  Future<List<Venue>> getFollowedVenuesByUserId(int userId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select('venue_id')
        .eq('user_id', userId);

    final List<int> followedVenueIds =
        response.map((item) => item['venue_id'] as int).toList();

    final List<Venue> allVenues = await VenueService().getVenues();

    return allVenues
        .where((venue) => followedVenueIds.contains(venue.id))
        .toList();
  }

  /// Récupère les utilisateurs qui suivent un venuee spécifique
  Future<List<AppUser.User>> getFollowersForVenue(int venueId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select('user_id')
        .eq('venue_id', venueId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(followerIds);
  }
}
