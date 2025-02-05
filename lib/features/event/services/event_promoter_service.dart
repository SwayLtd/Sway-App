import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class EventPromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PromoterService _promoterService = PromoterService();

  /// Retrieves promoters associated with a specific event.
  Future<List<Promoter>> getPromotersByEventId(int eventId) async {
    try {
      final response = await _supabase
          .from('event_promoter')
          .select('promoter_id')
          .eq('event_id', eventId);
      print('getPromotersByEventId Response: $response');
      if ((response.isEmpty)) {
        return [];
      }
      final List<int> promoterIds =
          response.map<int>((entry) => entry['promoter_id'] as int).toList();
      return await _promoterService.getPromotersByIds(promoterIds);
    } catch (e) {
      print('Error in getPromotersByEventId: $e');
      rethrow;
    }
  }

  /// Adds a promoter to an event.
  Future<void> addPromoterToEvent(int eventId, int promoterId) async {
    print('Adding promoter $promoterId to event $eventId');
    final response = await _supabase.from('event_promoter').insert({
      'event_id': eventId,
      'promoter_id': promoterId,
    }).select(); // Using .select() for confirmation.
    print('addPromoterToEvent Response: $response');
    if ((response.isEmpty)) {
      throw Exception('Failed to add promoter to event.');
    }
  }

  /// Removes a promoter from an event.
  Future<void> removePromoterFromEvent(int eventId, int promoterId) async {
    print('Removing promoter $promoterId from event $eventId');
    final response = await _supabase
        .from('event_promoter')
        .delete()
        .eq('event_id', eventId)
        .eq('promoter_id', promoterId)
        .select(); // Using .select() for confirmation.
    print('removePromoterFromEvent Response: $response');
    if ((response.isEmpty)) {
      throw Exception('Failed to remove promoter from event.');
    }
  }

  /// Updates the promoters associated with an event.
  Future<void> updateEventPromoters(int eventId, List<int> promoters) async {
    print(
        'Updating event promoters for event $eventId with promoters: $promoters');
    // Delete existing promoter entries for the event.
    await _supabase.from('event_promoter').delete().eq('event_id', eventId);
    // Prepare new entries.
    final entries = promoters
        .map((promoterId) => {
              'event_id': eventId,
              'promoter_id': promoterId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('event_promoter').insert(entries).select();
      print('updateEventPromoters Response: $response');
      if ((response.isEmpty)) {
        throw Exception('Failed to update event promoters.');
      }
    }
  }
}
