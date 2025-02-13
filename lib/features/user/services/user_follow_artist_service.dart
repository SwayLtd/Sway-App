// lib/features/user/services/user_follow_artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserFollowArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur suit un artiste spécifique
  Future<bool> isFollowingArtist(int artistId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    final response = await _supabase
        .from('user_follow_artist')
        .select()
        .eq('user_id', userId)
        .eq('artist_id', artistId);

    return response.isNotEmpty;
  }

  /// Suit un artiste
  Future<void> followArtist(int artistId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    await _supabase.from('user_follow_artist').insert({
      'user_id': userId,
      'artist_id': artistId,
    });
  }

  /// Ne suit plus un artiste
  Future<void> unfollowArtist(int artistId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated.');
    }

    await _supabase
        .from('user_follow_artist')
        .delete()
        .eq('user_id', userId)
        .eq('artist_id', artistId);
  }

  /// Récupère le nombre de followers d'un artiste
  Future<int> getArtistFollowersCount(int artistId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select('user_id')
        .eq('artist_id', artistId);

    return response.length;
  }

  /// Récupère les artistes suivis par un utilisateur spécifique
  Future<List<Artist>> getFollowedArtistsByUserId(int userId) async {
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
  }

  /// Récupère les utilisateurs qui suivent un artiste spécifique
  Future<List<AppUser.User>> getFollowersForArtist(int artistId) async {
    final response = await _supabase
        .from('user_follow_artist')
        .select('user_id')
        .eq('artist_id', artistId);

    final List<int> followerIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(followerIds);
  }
}
