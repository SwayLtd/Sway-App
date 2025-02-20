import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:isar/isar.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/models/isar_event.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/genre/models/isar_genre.dart';

class EventGenreService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EventService _eventService = EventService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves the genre IDs associated with a specific event.
  /// In online mode, it fetches from Supabase and updates the local IsarEvent record.
  /// In offline mode, it loads the genre IDs from the cached IsarEvent links.
  Future<List<int>> getGenresByEventId(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response = await _supabase
          .from('event_genre')
          .select('genre_id')
          .eq('event_id', eventId);
      if ((response as List).isEmpty) return [];
      final genreIds =
          response.map<int>((entry) => entry['genre_id'] as int).toList();

      // Update the local cache for the event.
      final isarEvent =
          await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
      if (isarEvent != null) {
        await _updateEventGenresCache(isarEvent, genreIds, isar);
      }
      return genreIds;
    } else {
      final isarEvent =
          await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
      if (isarEvent != null) {
        await isarEvent.genres.load();
        return isarEvent.genres.map((g) => g.remoteId).toList();
      }
      return [];
    }
  }

  /// Returns upcoming events associated with a given genre.
  /// In online mode, it fetches event IDs from Supabase and retrieves the events via EventService.
  /// In offline mode (or on error), it loads events from the local cache by filtering the IsarEvent links.
  Future<List<Event>> getUpcomingEventsByGenreId(int genreId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      try {
        final response = await _supabase
            .from('event_genre')
            .select('event_id')
            .eq('genre_id', genreId);
        if ((response as List).isEmpty) return [];
        final List<int> eventIds =
            response.map<int>((json) => json['event_id'] as int).toList();
        final events = await _eventService.getEventsByIds(eventIds);
        final now = DateTime.now();
        return events
            .where((event) => event.eventDateTime.isAfter(now))
            .toList();
      } catch (e) {
        print('Error in getUpcomingEventsByGenreId (online): $e');
        return await _loadUpcomingEventsByGenreFromCache(genreId, isar: isar);
      }
    } else {
      return await _loadUpcomingEventsByGenreFromCache(genreId, isar: isar);
    }
  }

  /// Adds a genre to an event on Supabase and updates the local cache.
  Future<void> addGenreToEvent(int eventId, int genreId) async {
    final online = await isConnected();
    if (!online)
      throw Exception('No internet connection to add genre to event.');

    final response = await _supabase.from('event_genre').insert({
      'event_id': eventId,
      'genre_id': genreId,
    }).select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to add genre to event.');
    }

    // Update local cache: add the genre to the event's IsarLinks.
    final isar = await _isarFuture;
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent != null) {
      await _storeGenreInEventCache(isarEvent, genreId, isar);
    }
  }

  /// Removes a genre from an event on Supabase and updates the local cache.
  Future<void> removeGenreFromEvent(int eventId, int genreId) async {
    final online = await isConnected();
    if (!online) throw Exception('No internet connection to remove genre.');

    final response = await _supabase
        .from('event_genre')
        .delete()
        .eq('event_id', eventId)
        .eq('genre_id', genreId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to remove genre from event.');
    }

    // Update local cache: remove the genre link from the event.
    final isar = await _isarFuture;
    final isarEvent =
        await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
    if (isarEvent != null) {
      await isarEvent.genres.load();
      isarEvent.genres.removeWhere((g) => g.remoteId == genreId);
      await isarEvent.genres.save();
    }
  }

  /// Updates the genres associated with an event on Supabase and updates the local cache.
  Future<void> updateEventGenres(int eventId, List<int> genreIds) async {
    final online = await isConnected();
    if (!online)
      throw Exception('No internet connection to update event genres.');

    // Delete existing records on Supabase.
    await _supabase.from('event_genre').delete().eq('event_id', eventId);
    // Insert new records.
    final entries = genreIds
        .map((genreId) => {
              'event_id': eventId,
              'genre_id': genreId,
            })
        .toList();
    if (entries.isNotEmpty) {
      final response =
          await _supabase.from('event_genre').insert(entries).select();
      if ((response as List).isEmpty) {
        throw Exception('Failed to update event genres.');
      }
      // Update local cache.
      final isar = await _isarFuture;
      final isarEvent =
          await isar.isarEvents.filter().remoteIdEqualTo(eventId).findFirst();
      if (isarEvent != null) {
        await _updateEventGenresCache(isarEvent, genreIds, isar);
      }
    }
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE
  // --------------------------------------------------------------------------

  /// Factorized function to update the genre links in a cached event.
  Future<void> _updateEventGenresCache(
      IsarEvent isarEvent, List<int> genreIds, Isar isar) async {
    await isar.writeTxn(() async {
      isarEvent.genres.clear();
      for (final id in genreIds) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(id).findFirst();
        if (isarGenre != null) {
          isarEvent.genres.add(isarGenre);
        }
      }
      await isarEvent.genres.save();
    });
  }

  /// Factorized helper to update the genre link in a cached event.
  Future<void> _storeGenreInEventCache(
      IsarEvent isarEvent, int genreId, Isar isar) async {
    await isar.writeTxn(() async {
      await isarEvent.genres.load();
      if (!isarEvent.genres.any((g) => g.remoteId == genreId)) {
        final isarGenre =
            await isar.isarGenres.filter().remoteIdEqualTo(genreId).findFirst();
        if (isarGenre != null) {
          isarEvent.genres.add(isarGenre);
          await isarEvent.genres.save();
        }
      }
    });
  }

  Future<List<Event>> _loadUpcomingEventsByGenreFromCache(int genreId,
      {required Isar isar}) async {
    try {
      final isarEvents = await isar.isarEvents
          .filter()
          .genres((q) => q.remoteIdEqualTo(genreId))
          .findAll();
      final now = DateTime.now();
      final upcomingIsarEvents = isarEvents
          .where((event) => event.eventDateTime.isAfter(now))
          .toList();

      // Convertir chaque IsarEvent en Event
      final upcomingEvents = upcomingIsarEvents.map((isarEvent) {
        return Event(
          id: isarEvent.remoteId,
          title: isarEvent.title,
          type: isarEvent.type,
          eventDateTime: isarEvent.eventDateTime,
          eventEndDateTime: isarEvent.eventEndDateTime,
          description: isarEvent.description,
          imageUrl: isarEvent.imageUrl,
          price: isarEvent.price,
          promoters: [], // à remplir si nécessaire
          genres: [], // à remplir si nécessaire
          artists: [], // à remplir si nécessaire
          interestedUsersCount: isarEvent.interestedUsersCount,
        );
      }).toList();

      return upcomingEvents;
    } catch (e) {
      print('Error in _loadUpcomingEventsByGenreFromCache: $e');
      return [];
    }
  }
}
