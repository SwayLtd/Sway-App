import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';

class UserInterestEventService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isInterestedInEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId);
  }

  Future<void> addInterest(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.add({'userId': userId, 'eventId': eventId});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> removeInterest(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId);

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> saveUserInterestEventData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<int> getEventInterestCount(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.where((interest) => interest['eventId'] == eventId).length;
  }

  Future<List<Event>> getInterestedEventsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> interestedEventIds = interestJson
        .where((interest) => interest['userId'] == userId)
        .map<String>((interest) => interest['eventId'] as String)
        .toList();

    // Assuming EventService has a method getEvents() to fetch all events
    final List<Event> allEvents = await EventService().getEvents();

    return allEvents.where((event) => interestedEventIds.contains(event.id)).toList();
  }
}
