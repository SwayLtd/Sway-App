// lib/features/event/services/event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';

// Import the regular Event model used for API exchange and UI
import 'package:sway/features/event/models/event_model.dart';
// Import the Isar models
import 'package:sway/features/event/models/isar_event.dart';
// Import the central DatabaseService
import 'package:sway/core/services/database_service.dart';

class EventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Returns all events from Supabase (online-first).
  Future<List<Event>> getEvents() async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase.from('events').select();
        if (response.isEmpty) {
          return await _loadAllEventsFromIsar(isar);
        }
        final fetchedEvents =
            response.map<Event>((json) => Event.fromJson(json)).toList();
        for (final event in fetchedEvents) {
          await _storeEventInIsar(isar, event);
        }
        return fetchedEvents;
      } catch (e) {
        return await _loadAllEventsFromIsar(isar);
      }
    } else {
      return await _loadAllEventsFromIsar(isar);
    }
  }

  /// Searches for events based on a query and additional filters.
  Future<List<Event>> searchEvents(
      String query, Map<String, dynamic> filters) async {
    // Start with a basic query.
    var builder = _supabase.from('events').select();

    // Apply title filter (case-insensitive search).
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
      builder = builder.eq('venue.city', cityFilter);
    }

    // Apply 'near_me' filter if needed (implementation pending).
    if (filters.containsKey('near_me') && filters['near_me'] is bool) {
      bool nearMeFilter = filters['near_me'] as bool;
      if (nearMeFilter) {
        // Implement geolocation logic here.
      }
    }

    final response = await builder;
    if (response.isEmpty) return [];
    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  /// Returns an event by ID using an offline-first approach.
  Future<Event?> getEventById(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      try {
        final response = await _supabase
            .from('events')
            .select()
            .eq('id', eventId)
            .maybeSingle();
        if (response == null) {
          return await _loadEventFromIsar(eventId, isar: isar);
        }
        final fetchedEvent = Event.fromJson(response);
        await _storeEventInIsar(isar, fetchedEvent);
        return fetchedEvent;
      } catch (e) {
        return await _loadEventFromIsar(eventId, isar: isar);
      }
    } else {
      return await _loadEventFromIsar(eventId, isar: isar);
    }
  }

  /// Returns events by a list of event IDs using an offline-first approach.
  Future<List<Event>> getEventsByIds(List<int?> eventIds) async {
    if (eventIds.isEmpty) return [];
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      try {
        // Build an 'or' filter string for Supabase.
        final String orFilter = eventIds.map((id) => 'id.eq.$id').join(',');
        final response = await _supabase.from('events').select().or(orFilter);
        if ((response as List).isEmpty) {
          return await _loadAllEventsFromIsar(isar);
        }
        final fetchedEvents =
            response.map<Event>((json) => Event.fromJson(json)).toList();
        // Update local cache.
        for (final event in fetchedEvents) {
          await _storeEventInIsar(isar, event);
        }
        return fetchedEvents;
      } catch (e) {
        print('Error in getEventsByIds (online): $e');
        return await _loadAllEventsFromIsar(isar);
      }
    } else {
      // Offline: load all events from local cache.
      return await _loadAllEventsFromIsar(isar);
    }
  }

  /// Returns only the metadata of an event by its ID from Supabase (online-first).
  Future<Map<String, dynamic>?> getEventMetadata(int eventId) async {
    final online = await isConnected();
    if (online) {
      try {
        final response = await _supabase
            .from('events')
            .select('metadata')
            .eq('id', eventId)
            .maybeSingle(); // We use maybeSingle to ensure that we either get a result or null.

        if (response != null && response['metadata'] != null) {
          return Map<String, dynamic>.from(response['metadata']);
        }
        return null;
      } catch (e) {
        print('Error fetching event metadata: $e');
        return null;
      }
    }
    return null; // Return null if offline or an error occurs.
  }

  /// Adds a new event to Supabase and stores it locally.
  Future<Event?> addEvent(Event event) async {
    final online = await isConnected();
    if (!online) return null;
    final response =
        await _supabase.from('events').insert(event.toJson()).select().single();
    final newEvent = Event.fromJson(response);
    final isar = await _isarFuture;
    await _storeEventInIsar(isar, newEvent);
    return newEvent;
  }

  /// Updates an existing event on Supabase and updates the local cache.
  Future<Event> updateEvent(Event event) async {
    final online = await isConnected();
    if (!online) throw Exception("No internet connection to update event.");
    final response = await _supabase
        .from('events')
        .update(event.toJson())
        .eq('id', event.id!)
        .select()
        .single();
    final updatedEvent = Event.fromJson(response);
    final isar = await _isarFuture;
    await _storeEventInIsar(isar, updatedEvent);
    return updatedEvent;
  }

  /// Deletes an event on Supabase and removes it from the local cache.
  Future<void> deleteEvent(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (online) {
      final response =
          await _supabase.from('events').delete().eq('id', eventId).select();
      if (response.isEmpty)
        throw Exception("Failed to delete event on server.");
    }
    await isar.writeTxn(() async {
      await isar.isarEvents.filter().remoteIdEqualTo(eventId).deleteAll();
    });
  }

  /// Returns the festival start time for a specific event.
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

  /// Returns top events based on the number of interested users.
  /// This example uses a Supabase RPC named 'get_top_events'.
  Future<List<Event>> getTopEvents({int? userId, int limit = 5}) async {
    try {
      // Construire les paramètres de l'appel RPC.
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };
      final data = await _supabase.rpc('get_top_events', params: params);
      if (data == null || (data as List).isEmpty) return [];
      final events = data
          .map<Event>((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
      // Stockage local optionnel
      final isar = await _isarFuture;
      for (final event in events) {
        await _storeEventInIsar(isar, event);
      }
      return events;
    } catch (e) {
      // Si l'appel en ligne échoue, on bascule sur le cache local
      final isar = await _isarFuture;
      return await _loadAllEventsFromIsar(isar);
    }
  }

  /// Returns recommended events for a user.
  /// Uses a Supabase RPC named 'get_recommended_events'.
  Future<List<Event>> getRecommendedEvents({int? userId, int limit = 5}) async {
    try {
      final params = <String, dynamic>{
        'p_user_id': userId,
        'p_limit': limit,
      };
      final response =
          await _supabase.rpc('get_recommended_events', params: params);
      if (response == null || (response as List).isEmpty) return [];
      final events = response
          .map<Event>((json) => Event.fromJson(json as Map<String, dynamic>))
          .toList();
      final isar = await _isarFuture;
      for (final event in events) {
        await _storeEventInIsar(isar, event);
      }
      return events;
    } catch (e) {
      // Offline fallback.
      final isar = await _isarFuture;
      return await _loadAllEventsFromIsar(isar);
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR EVENTS
  // --------------------------------------------------------------------------

  /// Stores an Event in Isar by wrapping the transaction.
  Future<void> _storeEventInIsar(Isar isar, Event event) async {
    await isar.writeTxn(() async {
      final isarEvent = IsarEvent()
        ..remoteId = event.id ?? 0
        ..title = event.title
        ..type = event.type
        ..eventDateTime = event.eventDateTime
        ..eventEndDateTime = event.eventEndDateTime
        ..description = event.description
        ..imageUrl = event.imageUrl
        ..interestedUsersCount = event.interestedUsersCount ?? 0;

      // TODO: Add linking for artists, genres, promoters, venue if needed.
      // Par exemple, pour chaque ID d'artiste présent dans event.artists, charger l'entité IsarArtist et l'ajouter au lien.

      await isar.isarEvents.put(isarEvent);
    });
  }

  /// Loads a single event from Isar by remoteId.
  Future<Event?> _loadEventFromIsar(int eventId, {required Isar isar}) async {
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent == null) return null;
    // TODO: Load linked entities if necessary.
    return Event(
      id: isarEvent.remoteId,
      title: isarEvent.title,
      type: isarEvent.type,
      eventDateTime: isarEvent.eventDateTime,
      eventEndDateTime: isarEvent.eventEndDateTime,
      description: isarEvent.description,
      imageUrl: isarEvent.imageUrl,
      promoters: [], // Populate if you store links.
      genres: [],
      artists: [],
      interestedUsersCount: isarEvent.interestedUsersCount,
    );
  }

  /// Loads all events from Isar.
  Future<List<Event>> _loadAllEventsFromIsar(Isar isar) async {
    final isarEvents = await isar.isarEvents.where().findAll();
    return isarEvents.map((isarEvent) {
      return Event(
        id: isarEvent.remoteId,
        title: isarEvent.title,
        type: isarEvent.type,
        eventDateTime: isarEvent.eventDateTime,
        eventEndDateTime: isarEvent.eventEndDateTime,
        description: isarEvent.description,
        imageUrl: isarEvent.imageUrl,
        promoters: [],
        genres: [],
        artists: [],
        interestedUsersCount: isarEvent.interestedUsersCount,
      );
    }).toList();
  }
}
