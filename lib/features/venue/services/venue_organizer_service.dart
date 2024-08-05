import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';

class VenuePromoterService {
  Future<List<Promoter>> getPromotersByVenueId(String venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/venue_promoters.json');
    final List<dynamic> venuePromoterJson = json.decode(response) as List<dynamic>;
    final promoterIds = venuePromoterJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['promoterId'] as String)
        .toList();

    final promoters = await PromoterService().getPromoters();

    final venuePromoters = promoters.where((promoter) => promoterIds.contains(promoter.id)).toList();

    return venuePromoters;
  }
}
