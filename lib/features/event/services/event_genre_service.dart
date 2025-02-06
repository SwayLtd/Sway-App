import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';

class EventGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retrieves the genres associated with a specific event.
  Future<List<int>> getGenresByEventId(int eventId) async {
    try {
      final response = await _supabase
          .from('event_genre')
          .select('genre_id')
          .eq('event_id', eventId);
      print('getGenresByEventId Response: $response');
      if ((response.isEmpty)) {
        return [];
      }
      return response.map<int>((entry) => entry['genre_id'] as int).toList();
    } catch (e) {
      print('Error in getGenresByEventId: $e');
      rethrow;
    }
  }

  /// Retrieves a list of upcoming events associated with a given genre.
  Future<List<Event>> getUpcomingEventsByGenreId(int genreId) async {
    try {
      // Retrieve event IDs linked to the specified genre from the event_genre table.
      final response = await _supabase
          .from('event_genre')
          .select('event_id')
          .eq('genre_id', genreId);

      if ((response as List).isEmpty) {
        return [];
      }

      // Extract event IDs from the response.
      final List<int> eventIds =
          response.map<int>((json) => json['event_id'] as int).toList();

      // Retrieve the events corresponding to the collected event IDs,
      // filtering to return only upcoming events (date_time greater than now).
      final nowIso = DateTime.now().toIso8601String();
      final eventsResponse = await _supabase
          .from('events')
          .select()
          .filter('id', 'in', eventIds)
          .gte('date_time', nowIso);

      if ((eventsResponse as List).isEmpty) {
        return [];
      }

      // Convert the list of JSON objects into a list of Event objects.
      return eventsResponse
          .map<Event>((json) => Event.fromJson(json))
          .toList();
    } catch (e) {
      print('Error in getUpcomingEventsByGenreId: $e');
      rethrow;
    }
  }

  /// Adds a genre to an event.
  Future<void> addGenreToEvent(int eventId, int genreId) async {
    print('Adding genre $genreId to event $eventId');
    final response = await _supabase.from('event_genre').insert({
      'event_id': eventId,
      'genre_id': genreId,
    }).select(); // Adding .select() for confirmation.
    print('addGenreToEvent Response: $response');
    if ((response.isEmpty)) {
      throw Exception('Failed to add genre to event.');
    }
  }

  /// Removes a genre from an event.
  Future<void> removeGenreFromEvent(int eventId, int genreId) async {
    print('Removing genre $genreId from event $eventId');
    final response = await _supabase
        .from('event_genre')
        .delete()
        .eq('event_id', eventId)
        .eq('genre_id', genreId)
        .select(); // Adding .select() for confirmation.
    print('removeGenreFromEvent Response: $response');
    if ((response.isEmpty)) {
      throw Exception('Failed to remove genre from event.');
    }
  }

  /// Updates the genres associated with an event.
  Future<void> updateEventGenres(int eventId, List<int> genres) async {
    print('Updating event genres for event $eventId with genres: $genres');
    // Delete existing genres for the event.
    await _supabase.from('event_genre').delete().eq('event_id', eventId);
    // Prepare new entries.
    final entries = genres
        .map((genreId) => {
              'event_id': eventId,
              'genre_id': genreId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('event_genre').insert(entries).select();
      print('updateEventGenres Response: $response');
      if ((response.isEmpty)) {
        throw Exception('Failed to update event genres.');
      }
    }
  }
}
