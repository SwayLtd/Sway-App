// lib/features/venue/services/venue_resident_artists_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class VenueResidentArtistsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();

  Future<List<Artist>> getArtistsByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_resident_artists')
        .select('artist_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> artistIds =
        response.map<int>((entry) => entry['artist_id'] as int).toList();

    return await _artistService.getArtistsByIds(artistIds);
  }

  Future<void> updateVenueArtists(int venueId, List<int> artists) async {
    // Supprimer les artistes existants
    await _supabase
        .from('venue_resident_artists')
        .delete()
        .eq('venue_id', venueId);

    // Ajouter les nouveaux artistes
    final entries = artists
        .map((artistId) => {
              'venue_id': venueId,
              'artist_id': artistId,
            })
        .toList();

    if (entries.isNotEmpty) {
      final response = await _supabase
          .from('venue_resident_artists')
          .insert(entries)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to update venue artists.');
      }
    }
  }

  Future<List<Venue>> getVenuesByArtistId(int artistId) async {
    final response = await _supabase
        .from('venue_resident_artists')
        .select('venue_id')
        .eq('artist_id', artistId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> venueIds =
        response.map((item) => item['venue_id'] as int).toList();

    return await VenueService().getVenuesByIds(venueIds);
  }
}
