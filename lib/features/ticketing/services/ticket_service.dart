import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sway/features/ticketing/models/ticket_model.dart';
import 'package:uuid/uuid.dart';

class TicketService {
  Future<List<Ticket>> getTicketsByEvent(int eventId) async {
    final String response = await rootBundle.loadString('assets/databases/tickets.json');
    final List<dynamic> ticketsJson = json.decode(response) as List<dynamic>;
    return ticketsJson.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).where((ticket) => ticket.eventId == eventId).toList();
  }

  Future<Ticket> getTicketById(int ticketId) async {
    final String response = await rootBundle.loadString('assets/databases/tickets.json');
    final List<dynamic> ticketsJson = json.decode(response) as List<dynamic>;
    return ticketsJson.map((json) => Ticket.fromJson(json as Map<String, dynamic>)).firstWhere((ticket) => ticket.id == ticketId);
  }

  Future<void> updateTicketStatus(int ticketId, String status) async {
    // Logic to update ticket status in the database
  }

  Future<void> createTicket(Ticket ticket) async {
    // Logic to create a new ticket in the database
  }

  // Méthode pour créer des tickets avec gestion des waves
  Future<void> createTicketsWithWave({
    required int eventId,
    required String ticketType,
    required String price,
    DateTime? waveEndDate,
    int? maxPurchases,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4() as int;

    final ticket = Ticket(
      id: id,
      eventId: eventId,
      ticketType: ticketType,
      price: price,
      status: 'active',
      createdAt: now,
      waveEndDate: waveEndDate,
      maxPurchases: maxPurchases,
    );

    await createTicket(ticket);
  }
}
