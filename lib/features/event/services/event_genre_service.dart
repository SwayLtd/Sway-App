import 'package:supabase_flutter/supabase_flutter.dart';

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
