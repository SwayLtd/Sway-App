// user_interest_event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserInterestEventService {
  final _supabase = Supabase.instance.client;
  final int userId = 3;

  Future<bool> isInterestedInEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'interested');

    return response.isNotEmpty;
  }

  Future<void> addInterest(int eventId) async {
    await _supabase.from('user_interest_event').insert({
      'user_id': userId,
      'event_id': eventId,
      'status': 'interested',
    });
  }

  Future<void> removeInterest(int eventId) async {
    await _supabase
        .from('user_interest_event')
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'interested');
  }

  Future<void> markEventAsGoing(int eventId) async {
    await _supabase
        .from('user_interest_event')
        .update({'status': 'going'})
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  Future<void> markEventAsAttended(int eventId) async {
    await _supabase
        .from('user_interest_event')
        .update({'status': 'attended'})
        .eq('user_id', userId)
        .eq('event_id', eventId);
  }

  Future<int> getEventInterestCount(int eventId, String status) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', status);

    return response.length;
  }

  Future<bool> isGoingToEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'going');

    return response.isNotEmpty;
  }

  Future<bool> isAttendedEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'attended');

    return response.isNotEmpty;
  }

  Future<List<Event>> getInterestedEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .filter('status', 'in', '("interested","going")');

    final List<int> eventIds =
        response.map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) => eventIds.contains(event.id) && event.dateTime.isAfter(now))
        .toList();
  }

  Future<List<Event>> getGoingEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .eq('status', 'going');

    final List<int> eventIds =
        response.map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) => eventIds.contains(event.id) && event.dateTime.isBefore(now))
        .toList();
  }

  Future<List<Event>> getAttendedEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .eq('status', 'attended');

    final List<int> eventIds =
        response.map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) => eventIds.contains(event.id) && event.dateTime.isBefore(now))
        .toList();
  }

  Future<List<AppUser.User>> getInterestedUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'interested');

    final List<int> userIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(userIds);
  }

  Future<List<AppUser.User>> getGoingUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'going');

    final List<int> userIds =
        response.map((item) => item['user_id'] as int).toList();

    return await UserService().getUsersByIds(userIds);
  }
}
