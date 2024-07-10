import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';

class VenueResidentArtistsService {
  Future<List<Artist>> getArtistsByVenueId(String venueId) async {
    
    try {
      final String response = await rootBundle.loadString('assets/databases/join_table/venue_resident_artists.json');

      final List<dynamic> venueArtistJson = json.decode(response) as List<dynamic>;

      final artistIds = venueArtistJson
          .where((entry) => entry['venueId'] == venueId)
          .map((entry) => entry['artistId'] as String)
          .toList();

      final artists = await ArtistService().getArtists();

      final residentArtists = artists.where((artist) => artistIds.contains(artist.id)).toList();

      return residentArtists;
    } catch (e) {
      return [];
    }
  }
}
