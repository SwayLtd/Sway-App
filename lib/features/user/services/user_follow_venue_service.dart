// lib/features/user/services/user_follow_venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowVenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isFollowingVenue(int venueId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_follow_venue')
          .select()
          .eq('user_id', userId)
          .eq('venue_id', venueId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status for venue $venueId: $e');
      return false;
    }
  }

  Future<void> followVenue(int venueId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_follow_venue').insert({
        'user_id': userId,
        'venue_id': venueId,
      });
    } catch (e) {
      print('Error following venue $venueId: $e');
    }
  }

  Future<void> unfollowVenue(int venueId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('user_follow_venue')
          .delete()
          .eq('user_id', userId)
          .eq('venue_id', venueId);
    } catch (e) {
      print('Error unfollowing venue $venueId: $e');
    }
  }

  Future<int> getVenueFollowersCount(int venueId) async {
    try {
      final response = await _supabase
          .from('user_follow_venue')
          .select('user_id')
          .eq('venue_id', venueId);

      return response.length;
    } catch (e) {
      print('Error getting followers count for venue $venueId: $e');
      return 0;
    }
  }

  Future<List<Venue>> getFollowedVenuesByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('user_follow_venue')
          .select('venue_id')
          .eq('user_id', userId);

      final List<int> followedVenueIds =
          response.map((item) => item['venue_id'] as int).toList();

      final List<Venue> allVenues = await VenueService().getVenues();

      return allVenues
          .where((venue) => followedVenueIds.contains(venue.id!))
          .toList();
    } catch (e) {
      print('Error getting followed venues for user $userId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getFollowersForVenue(int venueId) async {
    try {
      final response = await _supabase
          .from('user_follow_venue')
          .select('user_id')
          .eq('venue_id', venueId);

      final List<int> followerIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(followerIds);
    } catch (e) {
      print('Error getting followers for venue $venueId: $e');
      return [];
    }
  }
}
