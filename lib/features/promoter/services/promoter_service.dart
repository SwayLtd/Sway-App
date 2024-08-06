import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';

class PromoterService {
  Future<List<Promoter>> searchPromoters(String query) async {
    final String response =
        await rootBundle.loadString('assets/databases/promoters.json');
    final List<dynamic> promoterJson = json.decode(response) as List<dynamic>;

    final promoters = promoterJson.map((json) {
      return Promoter.fromJsonWithoutEvents(json as Map<String, dynamic>);
    }).toList();

    final results = promoters.where((promoter) {
      final matches =
          promoter.name.toLowerCase().contains(query.toLowerCase());
      return matches;
    }).toList();

    return results;
  }

  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Promoter>> getPromotersWithEvents() async {
    final String response =
        await rootBundle.loadString('assets/databases/promoters.json');
    final List<dynamic> promoterJson = json.decode(response) as List<dynamic>;

    // Charger les événements
    final List<Event> events = await EventService().getEvents();

    return promoterJson
        .map((json) => Promoter.fromJson(json as Map<String, dynamic>, events))
        .toList();
  }

  Future<Promoter?> getPromoterByIdWithEvents(String id) async {
    final List<Promoter> promoters = await getPromotersWithEvents();
    try {
      final Promoter promoter =
          promoters.firstWhere((promoter) => promoter.id == id);
      return promoter;
    } catch (e) {
      return null;
    }
  }

  Future<List<Promoter>> getPromoters() async {
    final String response =
        await rootBundle.loadString('assets/databases/promoters.json');
    final List<dynamic> promoterJson = json.decode(response) as List<dynamic>;

    return promoterJson
        .map((json) =>
            Promoter.fromJsonWithoutEvents(json as Map<String, dynamic>),)
        .toList();
  }

  Future<Promoter?> getPromoterById(String id) async {
    final List<Promoter> promoters = await getPromoters();
    try {
      final Promoter promoter =
          promoters.firstWhere((promoter) => promoter.id == id);
      return promoter;
    } catch (e) {
      return null;
    }
  }

  Future<void> addPromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        promoter.id, 'promoter', 'admin',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to add promoter
  }

  Future<void> updatePromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        promoter.id, 'promoter', 'manager',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to update promoter
  }

  Future<void> deletePromoter(String promoterId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
        promoterId, 'promoter', 'admin',);
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Logic to delete promoter
  }
}
