// lib/features/promoter/services/promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';

class PromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();

  Future<List<Promoter>> searchPromoters(String query) async {
    final response =
        await _supabase.from('promoters').select().ilike('name', '%$query%');

    if (response.isEmpty) {
      print('No promoters found.');
      return [];
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  Future<List<Promoter>> getPromotersWithEvents() async {
    final response = await _supabase.from('promoters').select();
    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    final events = await EventService().getEvents();

    return response
        .map<Promoter>((json) => Promoter.fromJson(json, events))
        .toList();
  }

  Future<Promoter?> getPromoterByIdWithEvents(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    // Récupérer les IDs des événements associés au promoteur
    final eventPromoterResponse = await _supabase
        .from('event_promoter')
        .select('event_id')
        .eq('promoter_id', id);

    final List<int> eventIds = eventPromoterResponse
        .map<int>((entry) => entry['event_id'] as int)
        .toList();

    if (eventIds.isEmpty) {
      // Aucun événement associé
      return Promoter.fromJson(response, []);
    }

    // Filtrer les événements à venir
    final now = DateTime.now();
    final upcomingEventsResponse = await _supabase
        .from('events')
        .select()
        .filter('id', 'in', eventIds)
        .gte('date_time', now.toIso8601String());

    final List<Event> upcomingEvents = upcomingEventsResponse
        .map<Event>((entry) => Event.fromJson(entry))
        .toList();

    return Promoter.fromJson(response, upcomingEvents);
  }

  Future<List<Promoter>> getPromoters() async {
    final response = await _supabase.from('promoters').select();

    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  Future<Promoter?> getPromoterById(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return Promoter.fromJsonWithoutEvents(response);
  }

  Future<void> addPromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id,
      'promoter',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response =
        await _supabase.from('promoters').insert(promoter.toJson());

    if (response.isEmpty) {
      throw Exception('Failed to add promoter.');
    }
  }

  Future<void> updatePromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id,
      'promoter',
      'manager',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase
        .from('promoters')
        .update(promoter.toJson())
        .eq('id', promoter.id);

    if (response.isEmpty) {
      throw Exception('Failed to update promoter.');
    }
  }

  Future<void> deletePromoter(int promoterId) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoterId,
      'promoter',
      'admin',
    );
    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response =
        await _supabase.from('promoters').delete().eq('id', promoterId);

    if (response.isEmpty) {
      throw Exception('Failed to delete promoter.');
    }
  }

  Future<List<Promoter>> getPromotersByIds(List<int> promoterIds) async {
    if (promoterIds.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('promoters')
        .select()
        .filter('id', 'in', promoterIds); // Utilisation de .filter au lieu de .in_

    if (response.isEmpty) {
      return [];
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }
}
