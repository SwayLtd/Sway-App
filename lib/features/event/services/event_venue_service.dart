// lib/features/event/services/event_venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class EventVenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VenueService _venueService = VenueService();

  /// Récupère la venue associée à un événement spécifique.
  Future<Venue?> getVenueByEventId(int eventId) async {
    try {
      // Effectuer la requête pour obtenir le venue_id associé à l'event_id
      final response = await _supabase
          .from('event_venue')
          .select('venue_id')
          .eq('event_id', eventId);

      // Log de la réponse
      print('getVenueByEventId Response: $response');

      // Vérifier si la réponse est vide ou non
      if (response.isEmpty) {
        return null;
      }

      // Extraire le venue_id
      int venueId = response.first['venue_id'] as int;

      // Utiliser VenueService pour récupérer les détails de la venue
      Venue? venue = await _venueService.getVenueById(venueId);

      return venue;
    } catch (e) {
      print('Error in getVenueByEventId: $e');
      return null;
    }
  }

  // Méthodes pour ajouter, supprimer ou modifier des venues à implémenter plus tard.
}
