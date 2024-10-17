// user_follow_venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowVenueService {
  final _supabase = Supabase.instance.client;
  final int userId = 3;

  Future<bool> isFollowingVenue(int venueId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select()
        .eq('user_id', userId)
        .eq('venue_id', venueId);

    return response.isNotEmpty;
  }

  Future<void> followVenue(int venueId) async {
    await _supabase.from('user_follow_venue').insert({
      'user_id': userId,
      'venue_id': venueId,
    });
  }

  Future<void> unfollowVenue(int venueId) async {
    await _supabase
        .from('user_follow_venue')
        .delete()
        .eq('user_id', userId)
        .eq('venue_id', venueId);
  }

  Future<int> getVenueFollowersCount(int venueId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select('user_id')
        .eq('venue_id', venueId);

    return response.length;
  }

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

  Future<List<AppUser.User>> getFollowersForVenue(int venueId) async {
    final response = await _supabase
        .from('user_follow_venue')
        .select('user_id')
        .eq('venue_id', venueId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
