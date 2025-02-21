// lib/features/artist/services/artist_service.dart

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';

// Import the regular Artist model used for API exchange and UI
import 'package:sway/features/artist/models/artist_model.dart';
// Import the Isar Artist model
import 'package:sway/features/artist/models/isar_artist.dart';
// Import the Isar Genre model for linking genres
import 'package:sway/features/genre/models/isar_genre.dart';

class ArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Returns an artist by ID using an offline-first approach.
  Future<Artist?> getArtistById(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase
            .from('artists')
            .select()
            .eq('id', artistId)
            .maybeSingle();
        if (response == null) {
          return await _loadArtistFromIsar(artistId, isar: isar);
        }
        final fetchedArtist = Artist.fromJson(response);
        await _storeArtistInIsar(isar, fetchedArtist);
        return fetchedArtist;
      } catch (e) {
        print("Error in getArtistById (online): $e");
        return await _loadArtistFromIsar(artistId, isar: isar);
      }
    } else {
      return await _loadArtistFromIsar(artistId, isar: isar);
    }
  }

  /// Returns all artists using an offline-first approach.
  Future<List<Artist>> getArtists() async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase.from('artists').select();
        if ((response as List).isEmpty) {
          return await _loadAllArtistsFromIsar(isar);
        }
        final fetchedArtists =
            response.map<Artist>((json) => Artist.fromJson(json)).toList();
        for (final artist in fetchedArtists) {
          await _storeArtistInIsar(isar, artist);
        }
        return fetchedArtists;
      } catch (e) {
        print("Error in getArtists (online): $e");
        return await _loadAllArtistsFromIsar(isar);
      }
    } else {
      return await _loadAllArtistsFromIsar(isar);
    }
  }

  /// Returns artists by a list of IDs using an offline-first approach.
  Future<List<Artist>> getArtistsByIds(List<int> artistIds) async {
    if (artistIds.isEmpty) return [];
    final online = await isConnected();
    final isar = await _isarFuture;

    // Récupérer les artistes présents dans le cache
    final isarArtists = await isar.isarArtists
        .filter()
        .anyOf(artistIds, (q, id) => q.remoteIdEqualTo(id))
        .findAll();

    // Construire une map pour garantir l'unicité (clé = remoteId)
    final Map<int, Artist> result = {};
    for (final isarArtist in isarArtists) {
      await isarArtist.genres.load();
      result[isarArtist.remoteId] = Artist(
        id: isarArtist.remoteId,
        name: isarArtist.name,
        imageUrl: isarArtist.imageUrl,
        description: isarArtist.description,
        isVerified: isarArtist.isVerified,
        followers: isarArtist.followers,
        isFollowing: isarArtist.isFollowing,
        genres: isarArtist.genres.map((g) => g.remoteId).toList(),
        upcomingEvents: [], // à compléter si nécessaire
        links: (jsonDecode(isarArtist.linksJson) as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }

    // Déterminer quels IDs sont manquants dans le cache
    final missingIds =
        artistIds.where((id) => !result.containsKey(id)).toList();

    if (missingIds.isNotEmpty) {
      // Vérifier la connexion pour récupérer les artistes manquants depuis Supabase
      if (online) {
        // Pour chaque artiste manquant, utiliser getArtistById qui gère le stockage en cache
        for (final id in missingIds) {
          final artist = await getArtistById(id);
          if (artist != null) {
            result[artist.id!] = artist;
          }
        }
      }
    }

    // print("getArtistsByIds: Requested IDs: $artistIds, retrieved: ${result.keys.toList()}");
    return result.values.toList();
  }

  /// Searches for artists by name using an offline-first approach.
  Future<List<Artist>> searchArtists(String query) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response =
            await _supabase.from('artists').select().ilike('name', '%$query%');
        if ((response as List).isEmpty) return [];
        final fetchedArtists =
            response.map<Artist>((json) => Artist.fromJson(json)).toList();
        for (final artist in fetchedArtists) {
          await _storeArtistInIsar(isar, artist);
        }
        return fetchedArtists;
      } catch (e) {
        print("Error in searchArtists (online): $e");
        return await _localArtistSearch(query, isar);
      }
    } else {
      return await _localArtistSearch(query, isar);
    }
  }

  /// Adds a new artist to the server and stores it locally.
  Future<Artist?> addArtist(Artist artist) async {
    final online = await isConnected();
    if (!online) return null;
    final artistData = artist.toJson();
    final response =
        await _supabase.from('artists').insert(artistData).select().single();
    final newArtist = Artist.fromJson(response);
    final isar = await _isarFuture;
    await _storeArtistInIsar(isar, newArtist);
    return newArtist;
  }

  /// Updates an existing artist on the server and stores updated data locally.
  Future<Artist> updateArtist(Artist artist) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection to update artist.");
    final response = await _supabase
        .from('artists')
        .update(artist.toJson())
        .eq('id', artist.id!)
        .select()
        .single();
    final updatedArtist = Artist.fromJson(response);
    final isar = await _isarFuture;
    await _storeArtistInIsar(isar, updatedArtist);
    return updatedArtist;
  }

  /// Deletes an artist by ID from the server and local cache.
  Future<void> deleteArtist(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response =
          await _supabase.from('artists').delete().eq('id', artistId).select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to delete artist on server.');
      }
    }
    await isar.writeTxn(() async {
      await isar.isarArtists.filter().remoteIdEqualTo(artistId).deleteAll();
    });
  }

  /// Returns top artists by genre ID.
  Future<List<Artist>> getTopArtistsByGenreId(int genreId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final artistGenreResponse = await _supabase
          .from('artist_genre')
          .select('artist_id')
          .eq('genre_id', genreId);
      if ((artistGenreResponse as List).isEmpty) {
        return [];
      }
      final artistIds = artistGenreResponse
          .map<int>((entry) => entry['artist_id'] as int)
          .toList();
      final artists = await getArtistsByIds(artistIds);
      artists.sort((a, b) => (b.followers ?? 0).compareTo(a.followers ?? 0));
      return artists;
    } else {
      final isarArtists = await isar.isarArtists
          .filter()
          .genres((q) => q.remoteIdEqualTo(genreId))
          .findAll();
      final Map<int, Artist> result = {};
      for (final isarArtist in isarArtists) {
        await isarArtist.genres.load();
        result[isarArtist.remoteId] = Artist(
          id: isarArtist.remoteId,
          name: isarArtist.name,
          imageUrl: isarArtist.imageUrl,
          description: isarArtist.description,
          isVerified: isarArtist.isVerified,
          followers: isarArtist.followers,
          isFollowing: isarArtist.isFollowing,
          genres: isarArtist.genres.map((g) => g.remoteId).toList(),
          upcomingEvents: [],
          links: (jsonDecode(isarArtist.linksJson) as Map<dynamic, dynamic>)
              .map((k, v) => MapEntry(k.toString(), v.toString())),
        );
      }
      final artists = result.values.toList();
      artists.sort((a, b) => (b.followers ?? 0).compareTo(a.followers ?? 0));
      return artists;
    }
  }

  /// Returns recommended artists by calling a Supabase RPC.
  Future<List<Artist>> getRecommendedArtists(
      {int? userId, int limit = 5}) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final params = <String, dynamic>{
          'p_user_id': userId,
          'p_limit': limit,
        };
        final response =
            await _supabase.rpc('get_recommended_artists', params: params);
        if (response == null || (response as List).isEmpty) return [];
        final recommendedArtists = (response)
            .map<Artist>(
                (json) => Artist.fromJson(json as Map<String, dynamic>))
            .toList();
        for (final artist in recommendedArtists) {
          await _storeArtistInIsar(isar, artist);
        }
        return recommendedArtists;
      } catch (e) {
        print("Error in getRecommendedArtists (online): $e");
        return await _loadAllArtistsFromIsar(isar);
      }
    } else {
      return [];
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE (Artist & Links)
  // --------------------------------------------------------------------------

  /// Stores an Artist in Isar (wrapped in a transaction).
  Future<void> _storeArtistInIsar(Isar isar, Artist artist) async {
    await isar.writeTxn(() async {
      // Try to find an existing record.
      final existing = await isar.isarArtists
          .filter()
          .remoteIdEqualTo(artist.id ?? 0)
          .findFirst();
      final isarArtist = existing ?? IsarArtist();
      isarArtist.remoteId = artist.id ?? 0;
      isarArtist.name = artist.name;
      isarArtist.imageUrl = artist.imageUrl;
      isarArtist.description = artist.description;
      isarArtist.isVerified = artist.isVerified;
      isarArtist.followers = artist.followers ?? 0;
      isarArtist.isFollowing = artist.isFollowing ?? false;
      isarArtist.linksJson =
          artist.links != null ? jsonEncode(artist.links) : '{}';

      // Link genres if available.
      isarArtist.genres.clear();
      if (artist.genres != null) {
        for (final genreId in artist.genres!) {
          final isarGenre = await isar.isarGenres
              .filter()
              .remoteIdEqualTo(genreId)
              .findFirst();
          if (isarGenre != null) {
            isarArtist.genres.add(isarGenre);
          }
        }
      }

      await isar.isarArtists.put(isarArtist);
      await isarArtist.genres.save();
    });
  }

  /// Loads a single Artist from Isar by remoteId.
  Future<Artist?> _loadArtistFromIsar(int artistId,
      {required Isar isar}) async {
    final isarArtist =
        await isar.isarArtists.filter().remoteIdEqualTo(artistId).findFirst();
    if (isarArtist == null) return null;
    await isarArtist.genres.load();
    return Artist(
      id: isarArtist.remoteId,
      name: isarArtist.name,
      imageUrl: isarArtist.imageUrl,
      description: isarArtist.description,
      isVerified: isarArtist.isVerified,
      followers: isarArtist.followers,
      isFollowing: isarArtist.isFollowing,
      genres: isarArtist.genres.map((g) => g.remoteId).toList(),
      upcomingEvents: [],
      links: (jsonDecode(isarArtist.linksJson) as Map<dynamic, dynamic>)
          .map((k, v) => MapEntry(k.toString(), v.toString())),
    );
  }

  /// Loads all Artists from Isar.
  Future<List<Artist>> _loadAllArtistsFromIsar(Isar isar) async {
    final isarArtists = await isar.isarArtists.where().findAll();
    final Map<int, Artist> result = {};
    for (final isarArtist in isarArtists) {
      await isarArtist.genres.load();
      result[isarArtist.remoteId] = Artist(
        id: isarArtist.remoteId,
        name: isarArtist.name,
        imageUrl: isarArtist.imageUrl,
        description: isarArtist.description,
        isVerified: isarArtist.isVerified,
        followers: isarArtist.followers,
        isFollowing: isarArtist.isFollowing,
        genres: isarArtist.genres.map((g) => g.remoteId).toList(),
        upcomingEvents: [],
        links: (jsonDecode(isarArtist.linksJson) as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    return result.values.toList();
  }

  /// Performs a local search for artists by name in Isar.
  Future<List<Artist>> _localArtistSearch(String query, Isar isar) async {
    final isarArtists = await isar.isarArtists
        .filter()
        .nameContains(query, caseSensitive: false)
        .findAll();
    final Map<int, Artist> result = {};
    for (final isarArtist in isarArtists) {
      await isarArtist.genres.load();
      result[isarArtist.remoteId] = Artist(
        id: isarArtist.remoteId,
        name: isarArtist.name,
        imageUrl: isarArtist.imageUrl,
        description: isarArtist.description,
        isVerified: isarArtist.isVerified,
        followers: isarArtist.followers,
        isFollowing: isarArtist.isFollowing,
        genres: isarArtist.genres.map((g) => g.remoteId).toList(),
        upcomingEvents: [],
        links: (jsonDecode(isarArtist.linksJson) as Map<dynamic, dynamic>)
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      );
    }
    return result.values.toList();
  }
}
