// lib/features/event/services/event_artist_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';

class EventArtistService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ArtistService _artistService = ArtistService();
  final EventService _eventService = EventService();

  /// Retrieves artists associated with a specific event.
  Future<List<Map<String, dynamic>>> getArtistsByEventId(int eventId) async {
    final response =
        await _supabase.from('event_artist').select().eq('event_id', eventId);
    if (response.isEmpty) return [];
    // Extract artist IDs and then map response including unique id.
    final Set<int> artistIds = {};
    for (final entry in response) {
      final artistIdField = entry['artist_id'];
      if (artistIdField is int) {
        artistIds.add(artistIdField);
      } else if (artistIdField is List) {
        artistIds.addAll(artistIdField.cast<int>());
      } else if (artistIdField is String) {
        final ids = artistIdField
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((id) => int.parse(id.trim()))
            .toList();
        artistIds.addAll(ids);
      }
    }
    final List<Artist> artists =
        await _artistService.getArtistsByIds(artistIds.toList());
    return response.map<Map<String, dynamic>>((entry) {
      final artistIdField = entry['artist_id'];
      List<Artist> associatedArtists = [];
      if (artistIdField is int) {
        associatedArtists =
            artists.where((artist) => artist.id == artistIdField).toList();
      } else if (artistIdField is List) {
        final ids = artistIdField.cast<int>();
        associatedArtists =
            artists.where((artist) => ids.contains(artist.id)).toList();
      } else if (artistIdField is String) {
        final ids = artistIdField
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((id) => int.parse(id.trim()))
            .toList();
        associatedArtists =
            artists.where((artist) => ids.contains(artist.id)).toList();
      }
      return {
        'id': entry['id'], // Unique assignment id
        'artists': associatedArtists,
        'custom_name': entry['custom_name'] as String?,
        'start_time': entry['start_time'] != null
            ? DateTime.parse(entry['start_time'])
            : null,
        'end_time': entry['end_time'] != null
            ? DateTime.parse(entry['end_time'])
            : null,
        'status': entry['status'] as String? ?? '',
        'stage': entry['stage'] as String? ?? '',
      };
    }).toList();
  }

  /// Adds a new artist assignment.
  Future<void> addArtistAssignment({
    required int eventId,
    required List<int> artistIds,
    required DateTime startTime,
    required DateTime endTime,
    String? customName,
    String status = 'confirmed',
    String? stage,
  }) async {
    final entry = {
      'event_id': eventId,
      'artist_id': artistIds,
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
  }

  /// Updates an existing artist assignment.
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
  }

  /// Deletes an artist assignment.
  Future<void> deleteArtistAssignment({
    required int eventId,
    required int assignmentId,
  }) async {
    final response = await _supabase
        .from('event_artist')
        .delete()
        .eq('id', assignmentId)
        .eq('event_id', eventId);
    // Si response est null ou vide, considérez la suppression comme réussie.
    if (response == null || (response is List && response.isEmpty)) {
      print('Assignment deletion: empty response considered as success.');
      return;
    }
  }

  /// Retrieves events associated with a specific artist.
  Future<List<Map<String, dynamic>>> getEventsByArtistId(int artistId) async {
    final response = await _supabase.from('event_artist').select();

    if (response.isEmpty) {
      return [];
    }

    final Set<int> eventIds = {};

    for (final entry in response) {
      final artistIdField = entry['artist_id'];

      bool artistMatches = false;

      if (artistIdField is int) {
        artistMatches = artistIdField == artistId;
      } else if (artistIdField is List) {
        artistMatches = artistIdField.contains(artistId);
      } else if (artistIdField is String) {
        // Gérer le cas où artist_id est une chaîne, ex: "[1]"
        final ids = artistIdField
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((id) => int.parse(id.trim()))
            .toList();
        artistMatches = ids.contains(artistId);
      }

      if (artistMatches) {
        eventIds.add(entry['event_id'] as int);
      }
    }

    if (eventIds.isEmpty) {
      return [];
    }

    final List<Event> events =
        await _eventService.getEventsByIds(eventIds.toList());

    return response.where((entry) {
      final artistIdField = entry['artist_id'];

      bool artistMatches = false;

      if (artistIdField is int) {
        artistMatches = artistIdField == artistId;
      } else if (artistIdField is List) {
        artistMatches = artistIdField.contains(artistId);
      } else if (artistIdField is String) {
        final ids = artistIdField
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((id) => int.parse(id.trim()))
            .toList();
        artistMatches = ids.contains(artistId);
      }

      return artistMatches;
    }).map<Map<String, dynamic>>((entry) {
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
  }

  /// Retrieves artists associated with a specific event and within a specific day.
  Future<List<Map<String, dynamic>>> getArtistsByEventIdAndDay(
    int eventId,
    DateTime day,
  ) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);

    // Get the festival start time
    final DateTime? festivalStartTime =
        await _eventService.getFestivalStartTime(eventId);

    if (festivalStartTime == null) {
      return [];
    }

    // Define the start time of the festival day based on the previous day
    DateTime dayStart;
    if (day.isAtSameMomentAs(festivalStartTime)) {
      dayStart = festivalStartTime;
    } else {
      dayStart = await _getPreviousDayEndTime(eventId, day);
    }

    final DateTime dayEnd = dayStart.add(const Duration(days: 1));

    final List<Map<String, dynamic>> filteredArtists = artists.where((entry) {
      final DateTime? startTime = entry['start_time'] as DateTime?;
      final DateTime? endTime = entry['end_time'] as DateTime?;

      if (startTime != null && endTime != null) {
        // Performance falls within the festival day window
        final bool isWithinDay =
            (startTime.isAfter(dayStart) && startTime.isBefore(dayEnd)) ||
                (endTime.isAfter(dayStart) && endTime.isBefore(dayEnd)) ||
                (startTime.isBefore(dayStart) && endTime.isAfter(dayStart));

        return isWithinDay;
      }
      return false;
    }).toList();

    return filteredArtists;
  }

  /// Helper method to get the end time of the previous day.
  Future<DateTime> _getPreviousDayEndTime(int eventId, DateTime day) async {
    final List<Map<String, dynamic>> artists =
        await getArtistsByEventId(eventId);

    final DateTime dayStart = DateTime(
      day.year,
      day.month,
      day.day,
      6,
    ); // Default start time for days after the first day
    DateTime previousDayEndTime = dayStart;

    for (final entry in artists) {
      final DateTime? endTime = entry['end_time'] != null
          ? DateTime.parse(entry['end_time'] as String)
          : null;
      if (endTime != null &&
          endTime.isBefore(day) &&
          endTime.isAfter(previousDayEndTime)) {
        previousDayEndTime = endTime;
      }
    }

    return previousDayEndTime;
  }
}
