// lib/features/user/services/user_interest_event_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/user/models/user_model.dart' as AppUser;
import 'package:sway/features/user/services/user_service.dart';

class UserInterestEventService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  /// Récupère l'ID de l'utilisateur actuellement connecté
  Future<int?> _getCurrentUserId() async {
    final currentUser = await _userService.getCurrentUser();
    return currentUser?.id;
  }

  /// Vérifie si l'utilisateur est intéressé par un événement spécifique
  Future<bool> isInterestedInEvent(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'interested');

    return response.isNotEmpty;
  }

  /// Ajoute un intérêt pour un événement
  Future<void> addInterest(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase.from('user_interest_event').insert({
      'user_id': userId,
      'event_id': eventId,
      'status': 'interested',
    });

    if (response.error != null) {
      throw Exception(
          'Erreur lors de l\'ajout de l\'intérêt pour l\'événement: ${response.error!.message}');
    }
  }

  /// Supprime un intérêt pour un événement
  Future<void> removeInterest(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_interest_event')
        .delete()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'interested');

    if (response.error != null) {
      throw Exception(
          'Erreur lors de la suppression de l\'intérêt pour l\'événement: ${response.error!.message}');
    }
  }

  /// Marque un événement comme "going"
  Future<void> markEventAsGoing(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_interest_event')
        .update({'status': 'going'})
        .eq('user_id', userId)
        .eq('event_id', eventId);

    if (response.error != null) {
      throw Exception(
          'Erreur lors du marquage de l\'événement comme "going": ${response.error!.message}');
    }
  }

  /// Récupère le nombre d'intérêts pour un événement avec un statut spécifique
  Future<int> getEventInterestCount(int eventId, String status) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', status);

    return response.length;
  }

  /// Vérifie si l'utilisateur va à un événement spécifique
  Future<bool> isGoingToEvent(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'going');

    return response.isNotEmpty;
  }

  /// Vérifie si l'utilisateur a assisté à un événement spécifique
  Future<bool> isGoingEvent(int eventId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      throw Exception('Utilisateur non authentifié.');
    }

    final response = await _supabase
        .from('user_interest_event')
        .select()
        .eq('user_id', userId)
        .eq('event_id', eventId)
        .eq('status', 'going');

    return response.isNotEmpty;
  }

  /// Récupère les événements intéressés par un utilisateur spécifique
  Future<List<Event>> getInterestedEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .filter('status', 'in', '("interested","going")');

    final List<int?> eventIds =
        response.map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) =>
            eventIds.contains(event.id!) && event.dateTime.isAfter(now))
        .toList();
  }

  /// Récupère les événements que l'utilisateur est "going"
  Future<List<Event>> getGoingEventsByUserId(int userId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('event_id')
        .eq('user_id', userId)
        .eq('status', 'going');

    final List<int?> eventIds =
        response.map((item) => item['event_id'] as int).toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents
        .where((event) =>
            eventIds.contains(event.id!) && event.dateTime.isBefore(now))
        .toList();
  }

  /// Récupère les utilisateurs intéressés par un événement spécifique
  Future<List<AppUser.User>> getInterestedUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'interested');

    final List<int> userIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(userIds);
  }

  /// Récupère les utilisateurs qui vont à un événement spécifique
  Future<List<AppUser.User>> getGoingUsersForEvent(int eventId) async {
    final response = await _supabase
        .from('user_interest_event')
        .select('user_id')
        .eq('event_id', eventId)
        .eq('status', 'going');

    final List<int> userIds =
        response.map((item) => item['user_id'] as int).toList();

    return await _userService.getUsersByIds(userIds);
  }
}
