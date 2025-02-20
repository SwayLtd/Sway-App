import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isFollowingArtist(int artistId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_follow_artist')
          .select()
          .eq('user_id', userId)
          .eq('artist_id', artistId);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking follow status for artist $artistId: $e');
      return false;
    }
  }

  Future<void> followArtist(int artistId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_follow_artist').insert({
        'user_id': userId,
        'artist_id': artistId,
      });
    } catch (e) {
      print('Error following artist $artistId: $e');
    }
  }

  Future<void> unfollowArtist(int artistId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase
          .from('user_follow_artist')
          .delete()
          .eq('user_id', userId)
          .eq('artist_id', artistId);
    } catch (e) {
      print('Error unfollowing artist $artistId: $e');
    }
  }

  Future<int> getArtistFollowersCount(int artistId) async {
    try {
      final response = await _supabase
          .from('user_follow_artist')
          .select('user_id')
          .eq('artist_id', artistId);

      return response.length;
    } catch (e) {
      print('Error getting followers count for artist $artistId: $e');
      return 0;
    }
  }

  Future<List<AppUser.User>> getFollowersForArtist(int artistId) async {
    try {
      final response = await _supabase
          .from('user_follow_artist')
          .select('user_id')
          .eq('artist_id', artistId);

      final List<int> followerIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(followerIds);
    } catch (e) {
      print('Error getting followers for artist $artistId: $e');
      return [];
    }
  }

  Future<List<Artist>> getFollowedArtistsByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('user_follow_artist')
          .select('artist_id')
          .eq('user_id', userId);

      final List<int> followedArtistIds =
          response.map((item) => item['artist_id'] as int).toList();

      final List<Artist> allArtists = await ArtistService().getArtists();

      return allArtists
          .where((artist) => followedArtistIds.contains(artist.id!))
          .toList();
    } catch (e) {
      print('Error getting followed artists for user $userId: $e');
      return [];
    }
  }
}
