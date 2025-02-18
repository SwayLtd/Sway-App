// lib/features/user/services/user_interest_event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserInterestEventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Retrieves the ID of the currently logged in user.
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Checks if the user is interested in a specific event.
  Future<bool> isInterestedInEvent(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'interested');
    // Le select retourne directement une List.
    return (response as List).isNotEmpty;
  }

  /// Upserts a new interest row for the given event with status 'interested'.
  Future<void> addInterest(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    // La méthode upsert ne retourne pas de réponse exploitable si on utilise maybeThrowOnError().
    await _supabase.from('user_interest_event').upsert(
      {
        'user_id': userId,
        'event_id': eventId,
        'status': 'interested',
      },
      onConflict: 'user_id,event_id',
    );
  }

  /// Upserts the interest row to status 'going' for the given event.
  Future<void> markEventAsGoing(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    await _supabase.from('user_interest_event').upsert(
      {
        'user_id': userId,
        'event_id': eventId,
        'status': 'going',
      },
      onConflict: 'user_id,event_id',
    );
  }

  /// Upserts the interest row to status 'not_interested' for the given event.
  Future<void> removeInterest(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    await _supabase.from('user_interest_event').upsert(
      {
        'user_id': userId,
        'event_id': eventId,
        'status': 'not_interested',
      },
      onConflict: 'user_id,event_id',
    );
  }

  /// Gets the number of interests for an event with a specific status.
  Future<int> getEventInterestCount(int eventId, String status) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', status);
    return (response as List).length;
  }

  /// Checks if the user is going to a specific event.
  Future<bool> isGoingToEvent(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception("User not authenticated.");
    }

    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'going');
    return (response as List).isNotEmpty;
  }

  /// Retrieves the events that a specific user is interested in.
  Future<List<Event>> getInterestedEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .filter('status', 'in', '("interested","going")');

    final List<int?> eventIds =
        (response as List).map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) =>
            eventIds.contains(event.id!) && event.eventDateTime.isAfter(now))
        .toList();
  }

  /// Retrieves the events that a specific user is going to.
  Future<List<Event>> getGoingEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .eq('status', 'going');

    final List<int?> eventIds =
        (response as List).map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) =>
            eventIds.contains(event.id!) && event.eventDateTime.isBefore(now))
        .toList();
  }

  /// Retrieves the users interested in a specific event.
  Future<List<AppUser.User>> getInterestedUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'interested');

    final List<int> userIds =
        (response as List).map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(userIds);
  }

  /// Retrieves the users who are going to a specific event.
  Future<List<AppUser.User>> getGoingUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'going');

    final List<int> userIds =
        (response as List).map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(userIds);
  }
}
