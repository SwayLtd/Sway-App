import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/venue/models/isar_venue.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';

class EventVenueService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final VenueService _venueService = VenueService();
  final EventService _eventService = EventService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves the venue associated with a specific event.
  /// In online mode, it fetches the venue ID from Supabase, updates the local cache,
  /// and returns the venue details.
  /// In offline mode, it attempts to load the event from the cache and then its venue link.
  Future<Venue?> getVenueByEventId(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      try {
        final response = await _supabase
            .from('event_venue')
            .select('venue_id')
            .eq('event_id', eventId);
        if ((response as List).isEmpty) return null;
        int venueId = response.first['venue_id'] as int;
        final venue = await _venueService.getVenueById(venueId);
        if (venue != null) {
          await _storeVenueInIsar(isar, venue);
        }
        return venue;
      } catch (e) {
        print('Error in getVenueByEventId (online): $e');
        return await _loadVenueFromCachedEvent(eventId, isar: isar);
      }
    } else {
      return await _loadVenueFromCachedEvent(eventId, isar: isar);
    }
  }

  /// Retrieves events associated with a specific venue.
  /// In online mode, it fetches event IDs from Supabase, updates the local cache,
  /// and returns upcoming events. In offline mode (or on error), it loads events from the local cache,
  /// filtering those whose linked venue matches the given venueId.
  Future<List<Map<String, dynamic>>> getEventsByVenueId(int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      try {
        final response = await _supabase
            .from('event_venue')
            .select('event_id')
            .eq('venue_id', venueId);
        if ((response as List).isEmpty) return [];

        // Extract event IDs from the response.
        final List<int> eventIds = [];
        for (final entry in response) {
          final dynamic eventIdField = entry['event_id'];
          if (eventIdField is int) {
            eventIds.add(eventIdField);
          } else if (eventIdField is List) {
            eventIds.addAll(eventIdField.cast<int>());
          } else if (eventIdField is String) {
            final ids = eventIdField
                .replaceAll('[', '')
                .replaceAll(']', '')
                .split(',')
                .map((id) => int.parse(id.trim()))
                .toList();
            eventIds.addAll(ids);
          }
        }
        if (eventIds.isEmpty) return [];

        // Retrieve events via EventService.
        final List<Event> events = await _eventService.getEventsByIds(eventIds);
        // Optionnel : Vous pouvez mettre à jour le cache local ici si nécessaire.

        final now = DateTime.now();
        final upcomingEvents =
            events.where((event) => event.eventDateTime.isAfter(now)).toList();

        final List<Map<String, dynamic>> eventsData = [];
        for (final event in upcomingEvents) {
          eventsData.add({
            'event': event,
            'start_time': event.eventDateTime.toIso8601String(),
            'end_time': event.eventDateTime.toIso8601String(),
            'status': '', // Add additional details if available.
            'stage': '',
          });
        }
        return eventsData;
      } catch (e) {
        print('Error in getEventsByVenueId (online): $e');
        // Fallback to offline branch.
        return await _loadEventsByVenueFromCache(venueId, isar: isar);
      }
    } else {
      return await _loadEventsByVenueFromCache(venueId, isar: isar);
    }
  }

  /// Adds a venue to an event.
  /// Checks connectivity and, if online and the operation succeeds,
  /// updates the local cache by setting the venue link in the cached event.
  Future<void> addVenueToEvent(int eventId, int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (!online) {
      throw Exception("No internet connection to add venue to event.");
    }

    final response = await _supabase.from('event_venue').insert({
      'event_id': eventId,
      'venue_id': venueId,
    }).select();

    if ((response as List).isEmpty) {
      throw Exception('Failed to add venue to event.');
    }

    // If successful, update the local cache.
    final venue = await _venueService.getVenueById(venueId);
    if (venue != null) {
      await _storeVenueInIsar(isar, venue);
    }
  }

  /// Removes a venue from an event.
  /// Checks connectivity and, if online and the operation succeeds,
  /// updates the local cache by clearing the venue link in the cached event.
  Future<void> removeVenueFromEvent(int eventId, int venueId) async {
    final online = await isConnected();
    if (!online) {
      throw Exception("No internet connection to remove venue from event.");
    }

    final response = await _supabase
        .from('event_venue')
        .delete()
        .eq('event_id', eventId)
        .eq('venue_id', venueId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to remove venue from event.');
    }

    // Update local cache: clear the venue link for the event.
    final isar = await _isarFuture;
    final cachedEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (cachedEvent != null) {
      cachedEvent.venue.value = null;
      await cachedEvent.venue.save();
    }
  }

  /// Updates the venue associated with an event.
  /// Checks connectivity, performs the update on Supabase (delete then insert),
  /// and, if successful, updates the local cache with the new venue link.
  Future<void> updateEventVenue(int eventId, int venueId) async {
    final online = await isConnected();
    final isar = await _isarFuture;
    if (!online) {
      throw Exception("No internet connection to update event venue.");
    }

    // Delete any existing venue record for the event.
    await _supabase.from('event_venue').delete().eq('event_id', eventId);

    // Insert the new venue record.
    final response = await _supabase.from('event_venue').insert({
      'event_id': eventId,
      'venue_id': venueId,
    }).select();

    if ((response as List).isEmpty) {
      throw Exception('Failed to update event venue.');
    }

    // Update local cache.
    final venue = await _venueService.getVenueById(venueId);
    if (venue != null) {
      await _storeVenueInIsar(isar, venue);
    }
  }

  Future<void> _storeVenueInIsar(Isar isar, Venue venue) async {
    await isar.writeTxn(() async {
      final isarVenue = IsarVenue()
        ..remoteId = venue.id ?? 0
        ..name = venue.name
        ..imageUrl = venue.imageUrl
        ..description = venue.description
        ..isVerified = venue.isVerified;
      await isar.isarVenues.put(isarVenue);
    });
  }

  /// Helper method that loads the venue from a cached event in Isar.
  /// It retrieves the event by its remoteId, loads the linked venue, and returns the venue if available.
  Future<Venue?> _loadVenueFromCachedEvent(int eventId,
      {required Isar isar}) async {
    final cachedEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (cachedEvent == null) return null;
    await cachedEvent.venue.load();
    if (cachedEvent.venue.value != null) {
      return Venue.fromJson({
        'id': cachedEvent.venue.value!.remoteId,
        'name': cachedEvent.venue.value!.name,
        'image_url': cachedEvent.venue.value!.imageUrl,
        'description': cachedEvent.venue.value!.description,
        'is_verified': cachedEvent.venue.value!.isVerified,
      });
    }
    return null;
  }

  /// Helper method: loads events from the local cache (Isar) filtering by the venue link.
  Future<List<Map<String, dynamic>>> _loadEventsByVenueFromCache(int venueId,
      {required Isar isar}) async {
    try {
      // Suppose that in your IsarEvent model, the venue is declared as:
      // final venue = IsarLink<IsarVenue>();
      final events = await isar.isarEvents
          .filter()
          .venue((q) => q.remoteIdEqualTo(venueId))
          .findAll();
      final now = DateTime.now();
      final upcomingEvents =
          events.where((event) => event.eventDateTime.isAfter(now)).toList();
      final List<Map<String, dynamic>> eventsData = [];
      for (final event in upcomingEvents) {
        eventsData.add({
          'event': event,
          'start_time': event.eventDateTime.toIso8601String(),
          'end_time': event.eventDateTime.toIso8601String(),
          'status': '',
          'stage': '',
        });
      }
      return eventsData;
    } catch (e) {
      print('Error in _loadEventsByVenueFromCache: $e');
      return [];
    }
  }
}
