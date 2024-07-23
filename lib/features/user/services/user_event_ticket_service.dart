import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway_events/features/user/models/user_event_ticket_model.dart';

class UserEventTicketService {
  Future<List<UserEventTicket>> getUserEventTickets() async {
    final String response = await rootBundle.loadString('assets/databases/join_table/user_event_ticket.json');
    final List<dynamic> jsonList = json.decode(response) as List<dynamic>;
    return jsonList.map((json) => UserEventTicket.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<void> addUserEventTicket(UserEventTicket userEventTicket) async {
    final List<UserEventTicket> currentTickets = await getUserEventTickets();
    currentTickets.add(userEventTicket);
    await saveUserEventTickets(currentTickets);
  }

  Future<void> updateUserEventTicket(UserEventTicket userEventTicket) async {
    final List<UserEventTicket> currentTickets = await getUserEventTickets();
    final index = currentTickets.indexWhere((ticket) => ticket.id == userEventTicket.id);
    if (index != -1) {
      currentTickets[index] = userEventTicket;
      await saveUserEventTickets(currentTickets);
    }
  }

  Future<void> deleteUserEventTicket(String id) async {
    final List<UserEventTicket> currentTickets = await getUserEventTickets();
    currentTickets.removeWhere((ticket) => ticket.id == id);
    await saveUserEventTickets(currentTickets);
  }

  Future<void> saveUserEventTickets(List<UserEventTicket> tickets) async {
    final String jsonString = json.encode(tickets.map((ticket) => ticket.toJson()).toList());
    // Save jsonString to your database or local storage
  }

  Future<List<UserEventTicket>> getUserTicketsByUserId(String userId) async {
    final List<UserEventTicket> allTickets = await getUserEventTickets();
    return allTickets.where((ticket) => ticket.userId == userId).toList();
  }

  Future<List<UserEventTicket>> getTicketsByEventId(String eventId) async {
    final List<UserEventTicket> allTickets = await getUserEventTickets();
    return allTickets.where((ticket) => ticket.eventId == eventId).toList();
  }
}
