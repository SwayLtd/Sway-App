// user_follow_artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowArtistService {
  final _supabase = Supabase.instance.client;
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isFollowingArtist(int artistId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select()
        .eq('user_id', userId)
        .eq('artist_id', artistId);

    return response.isNotEmpty;
  }

  Future<void> followArtist(int artistId) async {
    await _supabase.from('user_follow_artist').insert({
      'user_id': userId,
      'artist_id': artistId,
    });
  }

  Future<void> unfollowArtist(int artistId) async {
    await _supabase
        .from('user_follow_artist')
        .delete()
        .eq('user_id', userId)
        .eq('artist_id', artistId);
  }

  Future<int> getArtistFollowersCount(int artistId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select('user_id')
        .eq('artist_id', artistId);

    return response.length;
  }

  Future<List<Artist>> getFollowedArtistsByUserId(int userId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select('artist_id')
        .eq('user_id', userId);

    final List<int> followedArtistIds =
        response.map((item) => item['artist_id'] as int).toList();

    final List<Artist> allArtists = await ArtistService().getArtists();

    return allArtists
        .where((artist) => followedArtistIds.contains(artist.id))
        .toList();
  }

  Future<List<AppUser.User>> getFollowersForArtist(int artistId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select('user_id')
        .eq('artist_id', artistId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(followerIds);
  }
}
