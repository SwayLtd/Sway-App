// user_follow_event_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserInterestEventService {
  final String userId = "3"; // L'ID de l'utilisateur actuel

  Future<bool> isInterestedInEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
  }

  Future<void> addInterest(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "interested"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> removeInterest(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> markEventAsGoing(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "going"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> markEventAsAttended(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "going"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<int> getEventInterestCount(String eventId, String status) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    if (status == "both") {
      return interestJson.where((interest) => interest['eventId'] == eventId && (interest['status'] == "interested" || interest['status'] == "going")).length;
    } else {
      return interestJson.where((interest) => interest['eventId'] == eventId && interest['status'] == status).length;
    }
  }

  Future<bool> isGoingToEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "going");
  }

  Future<bool> isAttendedEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "going");
  }

  Future<List<Event>> getInterestedEventsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> interestedEventIds = interestJson
        .where((interest) => interest['userId'] == userId && (interest['status'] == "interested" || interest['status'] == "going"))
        .map<String>((interest) => interest['eventId'] as String)
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => interestedEventIds.contains(event.id) && DateTime.parse(event.dateTime).isAfter(now)).toList();
  }

  Future<List<Event>> getGoingEventsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> goingEventIds = interestJson
        .where((interest) => interest['userId'] == userId && interest['status'] == "going")
        .map<String>((interest) => interest['eventId'] as String)
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => goingEventIds.contains(event.id) && DateTime.parse(event.dateTime).isBefore(now)).toList();
  }

  Future<List<Event>> getAttendedEventsByUserId(String userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> attendedEventIds = interestJson
        .where((interest) => interest['userId'] == userId && interest['status'] == "going")
        .map<String>((interest) => interest['eventId'] as String)
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => attendedEventIds.contains(event.id) && DateTime.parse(event.dateTime).isBefore(now)).toList();
  }

  Future<void> saveUserInterestEventData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<List<User>> getInterestedUsersForEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> interestedUserIds = interestJson
        .where((interest) => interest['eventId'] == eventId && interest['status'] == "interested")
        .map<String>((interest) => interest['userId'] as String)
        .toList();

    return await UserService().getUsersByIds(interestedUserIds);
  }

  Future<List<User>> getGoingUsersForEvent(String eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List<String> goingUserIds = interestJson
        .where((interest) => interest['eventId'] == eventId && interest['status'] == "going")
        .map<String>((interest) => interest['userId'] as String)
        .toList();

    return await UserService().getUsersByIds(goingUserIds);
  }
}
