// lib/features/artist/services/artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';

class ArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();
  final UserFollowArtistService _userFollowArtistService =
      UserFollowArtistService();

  /// Search artists by name.
  Future<List<Artist>> searchArtists(String query) async {
    final response =
        await _supabase.from('artists').select().ilike('name', '%$query%');

    if (response.isEmpty) {
      print('No artists found.');
      return [];
    }

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  /// Get all artists with their upcoming events.
  Future<List<Artist>> getArtistsWithEvents() async {
    final response = await _supabase.from('artists').select();
    if (response.isEmpty) {
      throw Exception('No artists found.');
    }

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  /// Get events by a list of IDs.
  Future<List<Event>> getEventsByIds(List<int?> eventIds) async {
    if (eventIds.isEmpty) {
      return [];
    }

    final response =
        await _supabase.from('events').select().filter('id', 'in', eventIds);

    if (response.isEmpty) {
      return [];
    }

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Get an artist by ID with their upcoming events.
  Future<Artist?> getArtistByIdWithEvents(int id) async {
    final response =
        await _supabase.from('artists').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    // Retrieve associated event IDs from a join table (e.g., artist_event)
    final eventArtistResponse = await _supabase
        .from('artist_event')
        .select('event_id')
        .eq('artist_id', id);

    final List<int?> eventIds = eventArtistResponse
        .map<int>((entry) => entry['event_id'] as int)
        .toList();

    if (eventIds.isEmpty) {
      return Artist(
        id: response['id'],
        name: response['name'],
        imageUrl: response['image_url'],
        description: response['description'] ?? '',
        genres: List<int>.from(response['genres'] ?? []),
        upcomingEvents: [],
        similarArtists: List<int>.from(response['similarArtists'] ?? []),
        links: Map<String, String>.from(response['links'] ?? {}),
        followers: await _userFollowArtistService.getArtistFollowersCount(id),
        isFollowing: await _userFollowArtistService.isFollowingArtist(id),
      );
    }

    // Filter upcoming events
    final now = DateTime.now();
    final upcomingEventsResponse = await _supabase
        .from('events')
        .select()
        .filter('id', 'in', eventIds)
        .gte('date_time', now.toIso8601String());

    final List<int> upcomingEventIds =
        upcomingEventsResponse.map<int>((entry) => entry['id'] as int).toList();

    return Artist(
      id: response['id'],
      name: response['name'],
      imageUrl: response['image_url'],
      description: response['description'] ?? '',
      genres: List<int>.from(response['genres'] ?? []),
      upcomingEvents: upcomingEventIds,
      similarArtists: List<int>.from(response['similarArtists'] ?? []),
      links: Map<String, String>.from(response['links'] ?? {}),
      followers: await _userFollowArtistService.getArtistFollowersCount(id),
      isFollowing: await _userFollowArtistService.isFollowingArtist(id),
    );
  }

  /// Get all artists without their events.
  Future<List<Artist>> getArtists() async {
    final response = await _supabase.from('artists').select();

    if (response.isEmpty) {
      throw Exception('No artists found.');
    }

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  /// Get an artist by ID without their events.
  Future<Artist?> getArtistById(int id) async {
    final response =
        await _supabase.from('artists').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return Artist.fromJson(response);
  }

  /// Add a new artist.
  Future<Artist> addArtist(Artist artist) async {
    final artistData = artist.toJson();

    // Insert the artist into the database and retrieve the created object
    final response =
        await _supabase.from('artists').insert(artistData).select().single();

    return Artist.fromJson(response);
  }

  /// Update an existing artist.
  Future<Artist> updateArtist(Artist artist) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      artist.id!,
      'artist',
      'manager', // 'manager' or higher can update
    );

    if (!hasPermission) {
      throw Exception(
          'Permission denied: You do not have the necessary rights to update this artist.');
    }

    final response = await _supabase
        .from('artists')
        .update(artist.toJson())
        .eq('id', artist.id!)
        .select()
        .single();

    // Optionally, update followers and isFollowing
    final updatedArtist = Artist.fromJson(response).copyWith(
      followers:
          await _userFollowArtistService.getArtistFollowersCount(artist.id!),
      isFollowing: await _userFollowArtistService.isFollowingArtist(artist.id!),
    );

    return updatedArtist;
  }

  /// Delete an artist by ID.
  Future<void> deleteArtist(int artistId) async {
    final hasAdminPermission =
        await _permissionService.hasPermissionForCurrentUser(
      artistId,
      'artist',
      'admin',
    );

    if (!hasAdminPermission) {
      throw Exception(
          'Permission denied: You do not have the necessary rights to delete this artist.');
    }

    final response =
        await _supabase.from('artists').delete().eq('id', artistId);

    if (response.isEmpty) {
      throw Exception('Failed to delete artist.');
    }
  }

  /// Get artists by a list of IDs.
  Future<List<Artist>> getArtistsByIds(List<int> artistIds) async {
    if (artistIds.isEmpty) {
      return [];
    }

    final response =
        await _supabase.from('artists').select().filter('id', 'in', artistIds);

    if (response.isEmpty) {
      return [];
    }

    return response.map<Artist>((json) => Artist.fromJson(json)).toList();
  }

  /// Get top artists by genre ID.
  Future<List<Artist>> getTopArtistsByGenreId(int genreId) async {
    // Retrieve artist-genre relationships
    final artistGenreResponse = await _supabase
        .from('artist_genre')
        .select('artist_id')
        .eq('genre_id', genreId);

    if (artistGenreResponse.isEmpty) {
      return [];
    }

    final artistIds = artistGenreResponse
        .map<int>((entry) => entry['artist_id'] as int)
        .toList();

    if (artistIds.isEmpty) {
      return [];
    }

    // Retrieve artists by IDs
    final response =
        await _supabase.from('artists').select().filter('id', 'in', artistIds);

    if (response.isEmpty) {
      return [];
    }

    final artists =
        response.map<Artist>((json) => Artist.fromJson(json)).toList();

    // Fetch follower counts for all artists
    final Map<int, int> followerCounts = {};

    for (var artist in artists) {
      followerCounts[artist.id!] =
          await _userFollowArtistService.getArtistFollowersCount(artist.id!);
    }

    // Assign follower counts to artists
    final List<Artist> artistsWithFollowers = artists.map((artist) {
      return artist.copyWith(followers: followerCounts[artist.id!] ?? 0);
    }).toList();

    // Sort artists by follower count in descending order
    artistsWithFollowers
        .sort((a, b) => (b.followers ?? 0).compareTo(a.followers ?? 0));

    return artistsWithFollowers;
  }
}
