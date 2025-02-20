import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserInterestEventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();
  final EventService _eventService = EventService();

  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  Future<bool> isInterestedInEvent(int eventId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_interest_event')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'interested');

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking interest for event $eventId: $e');
      return false;
    }
  }

  Future<void> addInterest(int eventId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_interest_event').upsert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'interested',
      }, onConflict: 'user_id,event_id');
    } catch (e) {
      print('Error adding interest for event $eventId: $e');
    }
  }

  Future<void> markEventAsGoing(int eventId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_interest_event').upsert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'going',
      }, onConflict: 'user_id,event_id');
    } catch (e) {
      print('Error marking event as going for event $eventId: $e');
    }
  }

  Future<void> removeInterest(int eventId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      await _supabase.from('user_interest_event').upsert({
        'user_id': userId,
        'event_id': eventId,
        'status': 'not_interested',
      }, onConflict: 'user_id,event_id');
    } catch (e) {
      print('Error removing interest for event $eventId: $e');
    }
  }

  Future<int> getEventInterestCount(int eventId, String status) async {
    try {
      final response = await _supabase
          .from('user_interest_event')
          .select('user_id')
          .eq('event_id', eventId)
          .eq('status', status);

      return response.length;
    } catch (e) {
      print('Error getting interest count for event $eventId: $e');
      return 0;
    }
  }

  Future<bool> isGoingToEvent(int eventId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await _supabase
          .from('user_interest_event')
          .select()
          .eq('user_id', userId)
          .eq('event_id', eventId)
          .eq('status', 'going');

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking if going to event $eventId: $e');
      return false;
    }
  }

  Future<List<Event>> getInterestedEventsByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('user_interest_event')
          .select('event_id')
          .eq('user_id', userId)
          .filter('status', 'in', '("interested","going")');

      final List<int> eventIds =
          response.map((item) => item['event_id'] as int).toList();

      final List<Event> allEvents = await _eventService.getEvents();
      final DateTime now = DateTime.now();

      return allEvents
          .where((event) =>
              eventIds.contains(event.id!) && event.eventDateTime.isAfter(now))
          .toList();
    } catch (e) {
      print('Error getting interested events for user $userId: $e');
      return [];
    }
  }

  Future<List<Event>> getGoingEventsByUserId(int userId) async {
    try {
      final response = await _supabase
          .from('user_interest_event')
          .select('event_id')
          .eq('user_id', userId)
          .eq('status', 'going');

      final List<int> eventIds =
          response.map((item) => item['event_id'] as int).toList();

      final List<Event> allEvents = await _eventService.getEvents();
      final DateTime now = DateTime.now();

      return allEvents
          .where((event) =>
              eventIds.contains(event.id!) && event.eventDateTime.isBefore(now))
          .toList();
    } catch (e) {
      print('Error getting going events for user $userId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getInterestedUsersForEvent(int eventId) async {
    try {
      final response = await _supabase
          .from('user_interest_event')
          .select('user_id')
          .eq('event_id', eventId)
          .eq('status', 'interested');

      final List<int> userIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(userIds);
    } catch (e) {
      print('Error getting interested users for event $eventId: $e');
      return [];
    }
  }

  Future<List<AppUser.User>> getGoingUsersForEvent(int eventId) async {
    try {
      final response = await _supabase
          .from('user_interest_event')
          .select('user_id')
          .eq('event_id', eventId)
          .eq('status', 'going');

      final List<int> userIds =
          response.map((item) => item['user_id'] as int).toList();

      return await _userService.getUsersByIds(userIds);
    } catch (e) {
      print('Error getting going users for event $eventId: $e');
      return [];
    }
  }
}
