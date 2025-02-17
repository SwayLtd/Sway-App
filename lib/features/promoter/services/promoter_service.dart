// lib/features/promoter/services/promoter_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';

class PromoterService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();
  final EventService _eventService = EventService();

  /// Searches promoters by name.
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

  /// Retrieves all promoters with their associated events.
  Future<List<Promoter>> getPromotersWithEvents() async {
    final response = await _supabase.from('promoters').select();

    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    final events = await _eventService.getEvents();

    return response
        .map<Promoter>((json) => Promoter.fromJson(json, events))
        .toList();
  }

  /// Retrieves events by a list of IDs.
  Future<List<Event>> getEventsByIds(List<int?> eventIds) async {
    if (eventIds.isEmpty) {
      return [];
    }

    final response =
        await _supabase.from('events').select().filter('id', 'in', eventIds);

    if (response.isEmpty) {
      return [];
    }

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Retrieves a promoter by ID with upcoming events.
  Future<Promoter?> getPromoterByIdWithEvents(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    // Retrieve associated event IDs
    final eventPromoterResponse = await _supabase
        .from('event_promoter')
        .select('event_id')
        .eq('promoter_id', id);

    final List<int?> eventIds = eventPromoterResponse
        .map<int>((entry) => entry['event_id'] as int)
        .toList();

    if (eventIds.isEmpty) {
      // No associated events
      return Promoter.fromJsonWithoutEvents(response);
    }

    // Filter upcoming events
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

  /// Retrieves all promoters without their events.
  Future<List<Promoter>> getPromoters() async {
    final response = await _supabase.from('promoters').select();

    if (response.isEmpty) {
      throw Exception('No promoters found.');
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  /// Retrieves a promoter by ID without events.
  Future<Promoter?> getPromoterById(int id) async {
    final response =
        await _supabase.from('promoters').select().eq('id', id).maybeSingle();

    if (response == null) {
      return null;
    }

    return Promoter.fromJsonWithoutEvents(response);
  }

  /// Adds a new promoter.
  Future<Promoter> addPromoter(Promoter promoter) async {
    final promoterData = promoter.toJson();

    // Insert promoter into the database and retrieve the created object
    final response = await _supabase
        .from('promoters')
        .insert(promoterData)
        .select()
        .single();

    return Promoter.fromJsonWithoutEvents(response);
  }

  /// Updates an existing promoter.
  Future<Promoter> updatePromoter(Promoter promoter) async {
    final hasPermission = await _permissionService.hasPermissionForCurrentUser(
      promoter.id!,
      'promoter',
      2, // manager level (2) ou supérieur peut mettre à jour
    );

    if (!hasPermission) {
      throw Exception(
          'Permission denied: You do not have the necessary rights to update this promoter.');
    }

    final response = await _supabase
        .from('promoters')
        .update(promoter.toJson())
        .eq('id', promoter.id!)
        .select()
        .single();

    return Promoter.fromJsonWithoutEvents(response);
  }

  /// Deletes a promoter by ID.
  Future<void> deletePromoter(int promoterId) async {
    final hasAdminPermission =
        await _permissionService.hasPermissionForCurrentUser(
      promoterId,
      'promoter',
      3, // admin level (3) requis pour la suppression
    );

    if (!hasAdminPermission) {
      throw Exception(
          'Permission denied: You do not have the necessary rights to delete this promoter.');
    }

    try {
      print('Attempting to delete promoter with ID: $promoterId');

      // Execute the delete request with .select().execute()
      final response = await _supabase
          .from('promoters')
          .delete()
          .eq('id', promoterId)
          .select();

      print('Delete Promoter Response: $response');

      print('Promoter with ID: $promoterId has been deleted successfully.');
    } catch (e) {
      print('Delete Promoter Error: $e');
      throw e; // Rethrow the exception to be handled in the UI
    }
  }

  /// Retrieves promoters by a list of IDs.
  Future<List<Promoter>> getPromotersByIds(List<int> promoterIds) async {
    if (promoterIds.isEmpty) {
      return [];
    }

    final response = await _supabase
        .from('promoters')
        .select()
        .filter('id', 'in', promoterIds);

    if (response.isEmpty) {
      return [];
    }

    return response
        .map<Promoter>((json) => Promoter.fromJsonWithoutEvents(json))
        .toList();
  }

  Future<List<Promoter>> getRecommendedPromoters(
      {int? userId, int limit = 5}) async {
    try {
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };

      final response =
          await _supabase.rpc('get_recommended_promoters', params: params);

      if (response == null || (response as List).isEmpty) {
        return [];
      }

      return (response)
          .map<Promoter>(
              (json) => Promoter.fromJsonWithoutEvents(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching recommended promoters: $e');
      throw e;
    }
  }
}
