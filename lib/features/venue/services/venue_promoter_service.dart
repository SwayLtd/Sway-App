import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';

class VenuePromoterService {
  Future<List<Promoter>> getPromotersByVenueId(int venueId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/venue_promoter.json');
    final List venuePromoterJson = json.decode(response);
    final promoterIds = venuePromoterJson
        .where((entry) => entry['venueId'] == venueId)
        .map((entry) => entry['promoterId'])
        .toList();

    final promoters = await PromoterService().getPromoters();

    final venuePromoters = promoters.where((promoter) => promoterIds.contains(promoter.id)).toList();

    return venuePromoters;
  }
}
