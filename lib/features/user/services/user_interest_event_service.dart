// user_follow_event_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';

class UserInterestEventService {
  final int userId = 3; // L'ID de l'utilisateur actuel

  Future<bool> isInterestedInEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
  }

  Future<void> addInterest(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "interested"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> removeInterest(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> markEventAsGoing(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "going"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<void> markEventAsAttended(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    interestJson.removeWhere((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "interested");
    interestJson.add({'userId': userId, 'eventId': eventId, 'status': "going"});

    // Save updated list back to the file (assuming you have a method for this)
    await saveUserInterestEventData(interestJson);
  }

  Future<int> getEventInterestCount(int eventId, String status) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    if (status == "both") {
      return interestJson.where((interest) => interest['eventId'] == eventId && (interest['status'] == "interested" || interest['status'] == "going")).length;
    } else {
      return interestJson.where((interest) => interest['eventId'] == eventId && interest['status'] == status).length;
    }
  }

  Future<bool> isGoingToEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "going");
  }

  Future<bool> isAttendedEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    return interestJson.any((interest) => interest['userId'] == userId && interest['eventId'] == eventId && interest['status'] == "going");
  }

  Future<List<Event>> getInterestedEventsByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List interestedEventIds = interestJson
        .where((interest) => interest['userId'] == userId && (interest['status'] == "interested" || interest['status'] == "going"))
        .map<int>((interest) => interest['eventId'])
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => interestedEventIds.contains(event.id) && DateTime.parse(event.dateTime).isAfter(now)).toList();
  }

  Future<List<Event>> getGoingEventsByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List goingEventIds = interestJson
        .where((interest) => interest['userId'] == userId && interest['status'] == "going")
        .map<int>((interest) => interest['eventId'])
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => goingEventIds.contains(event.id) && DateTime.parse(event.dateTime).isBefore(now)).toList();
  }

  Future<List<Event>> getAttendedEventsByUserId(int userId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List attendedEventIds = interestJson
        .where((interest) => interest['userId'] == userId && interest['status'] == "going")
        .map<int>((interest) => interest['eventId'])
        .toList();

    final List<Event> allEvents = await EventService().getEvents();
    final DateTime now = DateTime.now();

    return allEvents.where((event) => attendedEventIds.contains(event.id) && DateTime.parse(event.dateTime).isBefore(now)).toList();
  }

  Future<void> saveUserInterestEventData(List<dynamic> data) async {
    // Implement saving logic here, depending on how you manage your local storage
  }

  Future<List<User>> getInterestedUsersForEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List interestedUserIds = interestJson
        .where((interest) => interest['eventId'] == eventId && interest['status'] == "interested")
        .map<int>((interest) => interest['userId'])
        .toList();

    return await UserService().getUsersByIds(interestedUserIds);
  }

  Future<List<User>> getGoingUsersForEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_interest_event.json');
    final List<dynamic> interestJson = json.decode(response) as List<dynamic>;

    final List goingUserIds = interestJson
        .where((interest) => interest['eventId'] == eventId && interest['status'] == "going")
        .map<int>((interest) => interest['userId'])
        .toList();

    return await UserService().getUsersByIds(goingUserIds);
  }
}
