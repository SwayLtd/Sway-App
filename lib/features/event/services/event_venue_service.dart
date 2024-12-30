// lib/features/event/services/event_venue_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';

class EventVenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VenueService _venueService = VenueService();
  final EventService _eventService = EventService();

  /// Récupère la venue associée à un événement spécifique.
  Future<Venue?> getVenueByEventId(int eventId) async {
    try {
      // Effectuer la requête pour obtenir le venue_id associé à l'event_id
      final response = await _supabase
          .from('event_venue')
          .select('venue_id')
          .eq('event_id', eventId);

      // Log de la réponse
      // print('getVenueByEventId Response: $response');

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

  /// Récupère les événements associés à un lieu spécifique.
  Future<List<Map<String, dynamic>>> getEventsByVenueId(int venueId) async {
    try {
      // Récupérer les relations entre événements et venues
      final response =
          await _supabase.from('event_venue').select().eq('venue_id', venueId);

      if ((response as List).isEmpty) {
        return [];
      }

      final List<Map<String, dynamic>> eventsData = [];

      final List<int> eventIds = [];

      // Extraire les event_ids associés au venue_id
      for (final entry in response as List<dynamic>) {
        final dynamic eventIdField = entry['event_id'];

        if (eventIdField is int) {
          eventIds.add(eventIdField);
        } else if (eventIdField is List) {
          eventIds.addAll(eventIdField.cast<int>());
        } else if (eventIdField is String) {
          // Gérer le cas où event_id est une chaîne, ex: "[1,2]"
          final ids = eventIdField
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((id) => int.parse(id.trim()))
              .toList();
          eventIds.addAll(ids);
        }
      }

      if (eventIds.isEmpty) {
        return [];
      }

      // Récupérer les détails des événements via EventService
      final List<Event> events = await _eventService.getEventsByIds(eventIds);

      // Filtrer les événements à venir
      final now = DateTime.now();
      final upcomingEvents =
          events.where((event) => event.dateTime.isAfter(now)).toList();

      // Construire la liste des événements avec les détails supplémentaires
      for (final event in upcomingEvents) {
        eventsData.add({
          'event': event,
          'start_time': event.dateTime.toIso8601String(),
          'end_time': event.endDateTime.toIso8601String(),
          'status': '', // Ajoutez les champs pertinents si disponibles
          'stage': '', // Ajoutez les champs pertinents si disponibles
        });
      }

      return eventsData;
    } catch (e) {
      print('Error in getEventsByVenueId: $e');
      return [];
    }
  }

  // Méthodes pour ajouter, supprimer ou modifier des venues à implémenter plus tard.
}
