// lib/features/venue/services/venue_promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class VenuePromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PromoterService _promoterService = PromoterService();

  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final response = await _supabase
        .from('venue_promoter')
        .select('promoter_id')
        .eq('venue_id', venueId);

    if (response.isEmpty) {
      return [];
    }

    final List<int> promoterIds =
        response.map((entry) => entry['promoter_id'] as int).toList();

    return await _promoterService.getPromotersByIds(promoterIds);
  }

  Future<void> addPromoterToVenue(int venueId, int promoterId) async {
    final response = await _supabase.from('venue_promoter').insert({
      'venue_id': venueId,
      'promoter_id': promoterId,
    });

    if (response.isEmpty) {
      throw Exception('Failed to add promoter to venue.');
    }
  }

  Future<void> removePromoterFromVenue(int venueId, int promoterId) async {
    final response = await _supabase
        .from('venue_promoter')
        .delete()
        .eq('venue_id', venueId)
        .eq('promoter_id', promoterId);

    if (response.isEmpty) {
      throw Exception('Failed to remove promoter from venue.');
    }
  }
}
