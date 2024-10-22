// lib/features/venue/services/venue_resident_artists_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';

class VenueResidentArtistsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();

  Future<List<Artist>> getArtistsByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_resident_artists')
        .select('artist_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> artistIds =
        response.map((entry) => entry['artist_id'] as int).toList();

    return await _artistService.getArtistsByIds(artistIds);
  }

  Future<void> addArtistToVenue(int venueId, int artistId) async {
    final response = await _supabase.from('venue_resident_artists').insert({
      'venue_id': venueId,
      'artist_id': artistId,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add artist to venue.');
    }
  }

  Future<void> removeArtistFromVenue(int venueId, int artistId) async {
    final response = await _supabase
        .from('venue_resident_artists')
        .delete()
        .eq('venue_id', venueId)
        .eq('artist_id', artistId);

    if (response.isEmpty) {
      throw Exception('Failed to remove artist from venue.');
    }
  }
}
