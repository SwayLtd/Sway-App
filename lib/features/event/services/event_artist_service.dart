// lib/features/event/services/event_artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/core/utils/connectivity_helper.dart';
// lib/features/event/services/event_artist_service.dart

import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/core/services/database_service.dart';
import 'package:isar/isar.dart';
import 'package:sway/features/event/models/isar_event_artist.dart'; // Cache model for assignments
import 'package:sway/features/event/services/event_service.dart';

class EventArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final EventService _eventService = EventService();
  late final Future<Isar> _isarFuture = DatabaseService().isar;

  /// Retrieves artist assignments for a specific event.
  /// - In online mode, fetches from Supabase, updates the local cache (assignments collection),
  ///   and returns a list of detailed assignment maps.
  /// - In offline mode, loads the assignments from the local cache.
  Future<List<Map<String, dynamic>>> getArtistsByEventId(int eventId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      final response =
          await _supabase.from('event_artist').select().eq('event_id', eventId);
      if ((response as List).isEmpty) {
        print(  "getArtistsByEventId: No assignments found for eventId $eventId (online).");
        return [];
      }

      // Cast each row to Map<String, dynamic>
      final List<Map<String, dynamic>> assignments =
          response.map<Map<String, dynamic>>((e) => e).toList();
      print("getArtistsByEventId: Raw assignments for eventId $eventId: $assignments");

      // Mise à jour du cache local des affectations via la nouvelle collection isarEventArtists.
      await _updateEventArtistAssignmentsCache(eventId, assignments);

      // Récupérer l'ensemble unique de tous les IDs d'artistes
      final Set<int> allArtistIds = {};
      for (final entry in assignments) {
        allArtistIds.addAll(_parseArtistField(entry['artist_id']));
      }
      print("getArtistsByEventId: Parsed artist IDs for eventId $eventId: $allArtistIds");

      // Récupérer les artistes complets via ArtistService et construire une map (id -> Artist)
      final List<Artist> artistList =
          await _artistService.getArtistsByIds(allArtistIds.toList());
      final Map<int, Artist> artistMap = {for (var a in artistList) a.id!: a};
      print("getArtistsByEventId: Artists retrieved via ArtistService: ${artistMap.keys.toList()}");

      // Pour chaque affectation, lire le champ artist_id (qui est supposé être une liste d'entiers)
      final List<Map<String, dynamic>> result = assignments.map((entry) {
        // Extraire la liste d'IDs en préservant l'ordre
        List<int> entryArtistIds;
        final dynamic artistField = entry['artist_id'];
        if (artistField is List) {
          entryArtistIds = List<int>.from(artistField);
        } else if (artistField is int) {
          entryArtistIds = [artistField];
        } else if (artistField is String) {
          entryArtistIds = artistField
              .replaceAll(RegExp(r'[\[\]]'), '')
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .where((id) => id != null)
              .cast<int>()
              .toList();
        } else {
          entryArtistIds = [];
        }
        // Construire la liste d'artistes en respectant l'ordre et en omettant ceux introuvables.
        final List<Artist> associatedArtists = entryArtistIds
            .map((id) => artistMap[id])
            .where((a) => a != null)
            .cast<Artist>()
            .toList();

        return {
          'id': entry['id'],
          'artists': associatedArtists,
          'custom_name': entry['custom_name'] as String?,
          'start_time': entry['start_time'] != null
              ? DateTime.parse(entry['start_time'] as String)
              : null,
          'end_time': entry['end_time'] != null
              ? DateTime.parse(entry['end_time'] as String)
              : null,
          'status': entry['status'] as String? ?? '',
          'stage': entry['stage'] as String? ?? '',
        };
      }).toList();

      print("getArtistsByEventId: Final result for eventId $eventId: ${result.map((r) => (r['artists'] as List).map((a) => (a as Artist).id).toList()).toList()}");
      return result;
    } else {
      // Offline: load assignments from the local cache (isarEventArtists collection).
      final cachedAssignments = await isar.isarEventArtists
          .filter()
          .eventIdEqualTo(eventId)
          .findAll();
      if (cachedAssignments.isNotEmpty) {
        // Gather unique artist IDs from cached assignments.
        final Set<int> uniqueArtistIds = {};
        for (final assignment in cachedAssignments) {
          uniqueArtistIds.addAll(assignment.artistIds);
        }
        final List<Artist> artists =
            await _artistService.getArtistsByIds(uniqueArtistIds.toList());
        // Construire la map id -> Artist.
        final Map<int, Artist> artistMap = {for (var a in artists) a.id!: a};

        final List<Map<String, dynamic>> result =
            cachedAssignments.map((assignment) {
          final List<Artist> associatedArtists = assignment.artistIds
              .map((id) => artistMap[id])
              .where((a) => a != null)
              .cast<Artist>()
              .toList();
          return {
            'id': assignment.remoteId,
            'artists': associatedArtists,
            'custom_name': assignment.customName,
            'start_time': assignment.startTime,
            'end_time': assignment.endTime,
            'status': assignment.status,
            'stage': assignment.stage,
          };
        }).toList();
        print(  "getArtistsByEventId (offline): Final cached result for eventId $eventId: ${result.map((r) => (r['artists'] as List).map((a) => (a as Artist).id).toList()).toList()}");
        return result;
      }
      print("getArtistsByEventId (offline): No cached assignments found for eventId $eventId.");
      return [];
    }
  }

  /// Retrieves artist assignments for a specific event filtered by a given day.
  Future<List<Map<String, dynamic>>> getArtistsByEventIdAndDay(
      int eventId, DateTime day) async {
    // Fetch assignments from Supabase (online mode assumed).
    final response =
        await _supabase.from('event_artist').select().eq('event_id', eventId);
    if ((response as List).isEmpty) return [];

    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final List<Map<String, dynamic>> filteredAssignments = [];
    for (final assignment in response) {
      if (assignment['start_time'] != null) {
        final startTime = DateTime.parse(assignment['start_time'] as String);
        if ((startTime.isAfter(dayStart) ||
                startTime.isAtSameMomentAs(dayStart)) &&
            startTime.isBefore(dayEnd)) {
          filteredAssignments.add(assignment);
        }
      }
    }

    final Set<int> artistIds = {};
    for (final assignment in filteredAssignments) {
      artistIds.addAll(_parseArtistField(assignment['artist_id']));
    }
    final artists = await _artistService.getArtistsByIds(artistIds.toList());
    print("getArtistsByEventIdAndDay: Artists retrieved for day ${day.toIso8601String()}: ${artists.map((a) => a.id).toList()}");

    return filteredAssignments.map((assignment) {
      final Set<int> entryIds = _parseArtistField(assignment['artist_id']);
      final List<Artist> assignmentArtists =
          artists.where((a) => entryIds.contains(a.id)).toList();
      return {
        'assignment': assignment,
        'artists': assignmentArtists,
      };
    }).toList();
  }

  /// Retrieves events associated with a specific artist.
  Future<List<Map<String, dynamic>>> getEventsByArtistId(int artistId) async {
    final online = await isConnected();
    final isar = await _isarFuture;

    if (online) {
      try {
        final response = await _supabase.from('event_artist').select();
        if ((response as List).isEmpty) return [];

        final Set<int> eventIds = {};
        for (final entry in response) {
          final dynamic artistField = entry['artist_id'];
          final Set<int> parsedIds = _parseArtistField(artistField);
          if (parsedIds.contains(artistId)) {
            eventIds.add(entry['event_id'] as int);
          }
        }
        if (eventIds.isEmpty) return [];

        final List<Event> events =
            await _eventService.getEventsByIds(eventIds.toList());
        print("getEventsByArtistId: Events retrieved for artistId $artistId: ${events.map((e) => e.id).toList()}");
        return response.where((entry) {
          final dynamic artistField = entry['artist_id'];
          final Set<int> parsedIds = _parseArtistField(artistField);
          return parsedIds.contains(artistId);
        }).map((entry) {
          final int eventId = entry['event_id'] as int;
          final matchingEvents = events.where((e) => e.id == eventId);
          final Event? event =
              matchingEvents.isNotEmpty ? matchingEvents.first : null;
          return {
            'event': event,
            'start_time': entry['start_time'] as String?,
            'end_time': entry['end_time'] as String?,
            'status': entry['status'] as String? ?? '',
            'stage': entry['stage'] as String? ?? '',
          };
        }).toList();
      } catch (e) {
        // Catching the error so it won't display an error on screen.
        print("Error fetching data: $e");
        return [];
        // Optionally, you could show a SnackBar here:
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to refresh data.")));
      }
    } else {
      // Offline: load assignments from the local cache (isarEventArtists collection).
      final cachedAssignments = await isar.isarEventArtists
          .filter()
          .artistIdsElementEqualTo(artistId)
          .findAll();
      if (cachedAssignments.isNotEmpty) {
        final Set<int> uniqueEventIds = {};
        for (final assignment in cachedAssignments) {
          uniqueEventIds.add(assignment.eventId);
        }
        final List<Event> events =
            await _eventService.getEventsByIds(uniqueEventIds.toList());
        final Map<int, Event> eventMap = {for (var e in events) e.id!: e};

        final List<Map<String, dynamic>> result =
            cachedAssignments.map((assignment) {
          final Event? event = eventMap[assignment.eventId];
          return {
            'event': event,
            'start_time': assignment.startTime.toIso8601String(),
            'end_time': assignment.endTime.toIso8601String(),
            'status': assignment.status,
            'stage': assignment.stage,
          };
        }).toList();
        print("getEventsByArtistId (offline): Final cached result for artistId $artistId: ${result.map((r) => (r['event'] as Event).id).toList()}");
        return result;
      }
      print("getEventsByArtistId (offline): No cached assignments found for artistId $artistId.");
      return [];
    }
  }

  /// Adds a new artist assignment on Supabase and updates the local cache.
  Future<void> addArtistAssignment({
    required int eventId,
    required List<int> artistIds,
    required DateTime startTime,
    required DateTime endTime,
    String? customName,
    String status = 'confirmed',
    String? stage,
  }) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to add artist assignment.');
    }
    final entry = {
      'event_id': eventId,
      'artist_id': artistIds, // Stored as a list, e.g. [10,12]
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'custom_name': customName,
      'status': status,
      'stage': stage,
    };
    final response =
        await _supabase.from('event_artist').insert(entry).select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to add artist assignment.');
    }
    print("addArtistAssignment: Assignment added successfully for eventId $eventId, artists: $artistIds");
    // Update local cache: store the new assignment.
    await _storeAssignmentInCache(response.first);
  }

  /// Updates an existing artist assignment on Supabase and updates the local cache.
  Future<void> updateArtistAssignment({
    required int eventId,
    required int assignmentId,
    required List<int> artistIds,
    required DateTime startTime,
    required DateTime endTime,
    String? customName,
    String status = 'confirmed',
    String? stage,
  }) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to update artist assignment.');
    }
    final entry = {
      'artist_id': artistIds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'custom_name': customName,
      'status': status,
      'stage': stage,
    };
    final response = await _supabase
        .from('event_artist')
        .update(entry)
        .eq('id', assignmentId)
        .eq('event_id', eventId)
        .select();
    if ((response as List).isEmpty) {
      throw Exception('Failed to update artist assignment.');
    }
    print("updateArtistAssignment: Assignment updated for eventId $eventId, artists: $artistIds");
    // Update local cache: re-store the updated assignment.
    await _storeAssignmentInCache(response.first);
  }

  /// Deletes an artist assignment on Supabase and updates the local cache.
  Future<void> deleteArtistAssignment({
    required int eventId,
    required int assignmentId,
  }) async {
    final online = await isConnected();
    if (!online) {
      throw Exception('No internet connection to delete artist assignment.');
    }
    final response = await _supabase
        .from('event_artist')
        .delete()
        .eq('id', assignmentId)
        .eq('event_id', eventId)
        .select();
    if ((response as List).isEmpty) {
      print("deleteArtistAssignment: Assignment deletion – empty response considered as success.");
    }
    // Remove the assignment from the local cache.
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      await isar.isarEventArtists
          .filter()
          .remoteIdEqualTo(assignmentId)
          .deleteAll();
    });
    print("deleteArtistAssignment: Cache updated for eventId $eventId, removed assignment: $assignmentId");
  }

  // --------------------------------------------------------------------------
  // HELPER METHODS FOR CACHE
  // --------------------------------------------------------------------------

  /// Helper method to store an assignment in the cache.
  /// It creates a new IsarEventArtist record with the complete assignment information.
  Future<void> _storeAssignmentInCache(Map<String, dynamic> assignment) async {
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      final newAssignment = IsarEventArtist()
        ..remoteId = assignment['id'] as int
        ..eventId = assignment['event_id'] as int
        ..artistIds = _parseArtistField(assignment['artist_id']).toList()
        ..startTime = DateTime.parse(assignment['start_time'] as String)
        ..endTime = DateTime.parse(assignment['end_time'] as String)
        ..customName = assignment['custom_name'] as String?
        ..status = assignment['status'] as String? ?? ''
        ..stage = assignment['stage'] as String?;
      await isar.isarEventArtists.put(newAssignment);
      print("Assignment stored in cache: eventId ${newAssignment.eventId}, artistIds ${newAssignment.artistIds}");
    });
  }

  /// Updates the local cache of artist assignments for a given event.
  /// It deletes existing cached assignments for the event and then inserts the new ones.
  Future<void> _updateEventArtistAssignmentsCache(
      int eventId, List<Map<String, dynamic>> assignments) async {
    final isar = await _isarFuture;
    await isar.writeTxn(() async {
      await isar.isarEventArtists.filter().eventIdEqualTo(eventId).deleteAll();
      for (final entry in assignments) {
        final newAssignment = IsarEventArtist()
          ..remoteId = entry['id'] as int
          ..eventId = entry['event_id'] as int
          ..artistIds = _parseArtistField(entry['artist_id']).toList()
          ..startTime = DateTime.parse(entry['start_time'] as String)
          ..endTime = DateTime.parse(entry['end_time'] as String)
          ..customName = entry['custom_name'] as String?
          ..status = entry['status'] as String? ?? ''
          ..stage = entry['stage'] as String?;
        await isar.isarEventArtists.put(newAssignment);
      }
    });
    print("Cache updated for eventId $eventId with assignments from online data.");
  }

  /// Helper function to parse the artist_field into a Set<int> (unique artist IDs).
  Set<int> _parseArtistField(dynamic artistField) {
    final Set<int> ids = {};
    if (artistField is List) {
      ids.addAll(artistField.cast<int>());
    } else if (artistField is int) {
      ids.add(artistField);
    } else if (artistField is String) {
      // Remove brackets and split by comma.
      final cleaned = artistField.replaceAll(RegExp(r'[\[\]]'), '');
      final parts = cleaned.split(',');
      for (final part in parts) {
        final id = int.tryParse(part.trim());
        if (id != null) {
          ids.add(id);
        }
      }
    }
    return ids;
  }
}
