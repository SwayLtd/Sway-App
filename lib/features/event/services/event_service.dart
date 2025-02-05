// lib/features/event/services/event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/user/models/user_event_ticket_model.dart';
import 'package:sway/features/user/services/user_event_ticket_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserPermissionService _permissionService = UserPermissionService();
  final UserEventTicketService _userEventTicketService =
      UserEventTicketService();

  /// Retrieves all events from Supabase.
  Future<List<Event>> getEvents() async {
    final response = await _supabase.from('events').select();

    if (response.isEmpty) {
      throw Exception('No events found.');
    }

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Retrieves a single event by its ID from Supabase.
  Future<Event?> getEventById(int eventId) async {
    final response =
        await _supabase.from('events').select().eq('id', eventId).maybeSingle();

    if (response == null) {
      return null;
    }

    return Event.fromJson(response);
  }

  /// Searches for events based on a query and additional filters.
  Future<List<Event>> searchEvents(
      String query, Map<String, dynamic> filters) async {
    // Initialize the query builder.
    var builder = _supabase.from('events').select();

    // Apply title filter using ILIKE for case-insensitive search.
    if (query.isNotEmpty) {
      builder = builder.ilike('title', '%$query%');
    }

    // Apply date filter if provided.
    if (filters.containsKey('date') && filters['date'] is DateTime) {
      DateTime dateFilter = filters['date'] as DateTime;
      String startOfDay =
          DateTime(dateFilter.year, dateFilter.month, dateFilter.day)
              .toIso8601String();
      String endOfDay = DateTime(
              dateFilter.year, dateFilter.month, dateFilter.day, 23, 59, 59)
          .toIso8601String();
      builder = builder.gte('date_time', startOfDay).lte('date_time', endOfDay);
    }

    // Apply genre filter if provided.
    if (filters.containsKey('genres') && filters['genres'] is List<int>) {
      List<int> genreFilter = filters['genres'] as List<int>;
      if (genreFilter.isNotEmpty) {
        String orFilter =
            genreFilter.map((genreId) => 'genre_id.eq.$genreId').join(',');
        builder = builder.or(orFilter);
      }
    }

    // Apply city filter if provided.
    if (filters.containsKey('city') && filters['city'] is String) {
      String cityFilter = filters['city'] as String;
      // Assuming there is a foreign key relationship set up in Supabase between events and venues.
      // Replace 'venues.city' with the actual field path if different.
      builder = builder.eq('venue.city', cityFilter);
    }

    // Apply 'near_me' filter if needed (implementation pending).
    if (filters.containsKey('near_me') && filters['near_me'] is bool) {
      bool nearMeFilter = filters['near_me'] as bool;
      if (nearMeFilter) {
        // Implement the "near me" logic here.
        // This might involve geolocation queries which require additional setup.
      }
    }

    final response = await builder;

    if (response.isEmpty) {
      return [];
    }

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Adds a new event to Supabase.
  Future<Event> addEvent(Event event) async {
    // Ensure that the event has at least one promoter.
    if (event.promoters == null || event.promoters!.isEmpty) {
      throw Exception('No promoter provided for the event.');
    }
    // Check permission on the selected promoter (assume first promoter in the list).
    final int promoterId = event.promoters!.first;
    final bool hasPermission =
        await _permissionService.hasPermissionForCurrentUser(
      promoterId,
      'promoter',
      'manager', // User must be at least manager (or admin) on the promoter.
    );
    print('Checking permission for promoter $promoterId: $hasPermission');
    if (!hasPermission) {
      throw Exception('Permission denied');
    }
    // Inserting the event.
    print('Inserting event: ${event.toJson()}');
    final response =
        await _supabase.from('events').insert(event.toJson()).select().single();
    print('Insert response: $response');
    if ((response is List && response.isEmpty)) {
      throw Exception('Failed to add event.');
    }

    return Event.fromJson(response);
  }

  /// Updates an existing event in Supabase.
  /// Au lieu de Future<void>, on peut retourner Future<Event> pour
  /// récupérer l'Event mis à jour comme vous le faites côté Promoter.
  Future<Event> updateEvent(Event event) async {
    final bool hasPermission =
        await _permissionService.hasPermissionForCurrentUser(
      event.id!,
      'event',
      'manager',
    );

    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final updatedRow = await _supabase
        .from('events')
        .update(event.toJson())
        .eq('id', event.id!)
        .select()
        .single();

    // Convertir la réponse en Event
    return Event.fromJson(updatedRow);
  }

  /// Deletes an event from Supabase.
  Future<void> deleteEvent(int eventId) async {
    final bool hasPermission =
        await _permissionService.hasPermissionForCurrentUser(
      eventId,
      'event',
      'admin',
    );

    if (!hasPermission) {
      throw Exception('Permission denied');
    }

    final response = await _supabase.from('events').delete().eq('id', eventId);

    if (response.isEmpty) {
      throw Exception('Failed to delete event.');
    }
  }

  /// Retrieves user tickets for a specific event.
  Future<List<UserEventTicket>> getUserTicketsForEvent(int eventId) async {
    return await _userEventTicketService.getTicketsByEventId(eventId);
  }

  /// Retrieves events by a list of event IDs.
  Future<List<Event>> getEventsByIds(List<int?> eventIds) async {
    if (eventIds.isEmpty) {
      return [];
    }

    // Build the 'or' filter for Supabase.
    final String orFilter = eventIds.map((id) => 'id.eq.$id').join(',');

    final response = await _supabase.from('events').select().or(orFilter);

    if (response.isEmpty) {
      return [];
    }

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Retrieves the festival start time for a specific event.
  Future<DateTime?> getFestivalStartTime(int eventId) async {
    final response = await _supabase
        .from('events')
        .select('date_time')
        .eq('id', eventId)
        .maybeSingle();

    if (response != null && response.containsKey('date_time')) {
      return DateTime.parse(response['date_time'] as String);
    }
    return null;
  }

  /// Récupère les événements les plus populaires basés sur le nombre d'utilisateurs intéressés.
  Future<List<Event>> getTopEvents({int limit = 5}) async {
    try {
      final data =
          await _supabase.rpc('get_top_events', params: {'p_limit': limit});
      // print('getTopEvents data: $data');

      if (data == null || (data as List).isEmpty) {
        return [];
      }

      return (data)
          .map<Event>((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching top events: $e');
      throw e;
    }
  }
}
