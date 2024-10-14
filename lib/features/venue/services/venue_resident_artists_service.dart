import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';

class VenueResidentArtistsService {
  Future<List<Artist>> getArtistsByVenueId(int venueId) async {
    
    try {
      final String response = await rootBundle.loadString('assets/databases/join_table/venue_resident_artists.json');

      final List venueArtistJson = json.decode(response);

      final artistIds = venueArtistJson
          .where((entry) => entry['venue_id'] == venueId)
          .map((entry) => entry['artist_id'])
          .toList();

      final artists = await ArtistService().getArtists();

      final residentArtists = artists.where((artist) => artistIds.contains(artist.id)).toList();

      return residentArtists;
    } catch (e) {
      return [];
    }
  }
}
