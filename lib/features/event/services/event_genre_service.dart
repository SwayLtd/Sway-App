// lib/features/event/services/event_genre_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class EventGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Retrieves genres associated with a specific event.
  Future<List<int>> getGenresByEventId(int eventId) async {
    try {
      // Fetch event_genre relations from Supabase
      final response = await _supabase
          .from('event_genre')
          .select('genre_id')
          .eq('event_id', eventId);

      // Log the response
      print('getGenresByEventId Response: $response');

      if (response.isEmpty) {
        return [];
      }

      // Extract genre IDs
      return response.map<int>((entry) => entry['genre_id'] as int).toList();
    } catch (e) {
      print('Error in getGenresByEventId: $e');
      rethrow;
    }
  }
}
