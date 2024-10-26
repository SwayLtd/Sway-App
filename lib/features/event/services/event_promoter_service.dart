// lib/features/event/services/event_promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class EventPromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PromoterService _promoterService = PromoterService();

  /// Retrieves promoters associated with a specific event.
  Future<List<Promoter>> getPromotersByEventId(int eventId) async {
    try {
      // Fetch event_promoter relations from Supabase
      final response = await _supabase
          .from('event_promoter')
          .select('promoter_id')
          .eq('event_id', eventId);

      // Log the response
      print('getPromotersByEventId Response: $response');

      if (response.isEmpty) {
        return [];
      }

      // Extract promoter IDs
      final List<int> promoterIds = response
          .map<int>((entry) => entry['promoter_id'] as int)
          .toList();

      // Fetch promoters by IDs
      return await _promoterService.getPromotersByIds(promoterIds);
    } catch (e) {
      print('Error in getPromotersByEventId: $e');
      rethrow;
    }
  }
}
