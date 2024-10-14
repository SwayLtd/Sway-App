import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';

class EventPromoterService {
  Future<List<Promoter>> getPromotersByEventId(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/event_promoter.json');
    final List<dynamic> eventPromoterJson = json.decode(response) as List<dynamic>;
    final promoterIds = eventPromoterJson
        .where((entry) => entry['event_id'] == eventId)
        .map((entry) => entry['promoter_id'])
        .toList();

    final promoters = await PromoterService().getPromoters();
    return promoters.where((promoter) => promoterIds.contains(promoter.id)).toList();
  }
}