// ticketing.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/ticketing/screens/event_tickets_screen.dart';
import 'package:sway_events/features/user/models/user_event_ticket_model.dart';
import 'package:sway_events/features/user/services/user_event_ticket_service.dart';

class TicketingScreen extends StatelessWidget {
  final EventService _eventService = EventService();
  final UserEventTicketService _userEventTicketService = UserEventTicketService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("My Tickets"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Upcoming"),
              Tab(text: "Past"),
            ],
          ),
        ),
        body: FutureBuilder<List<UserEventTicket>>(
          future: _userEventTicketService.getUserTicketsByUserId(3), // Replace with actual user ID fetching logic
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No tickets found'));
            } else {
              final userTickets = snapshot.data!;
              final eventIds = userTickets.map((ticket) => ticket.eventId).toSet().toList();
              
              return FutureBuilder<List<Event>>(
                future: _eventService.getEventsByIds(eventIds),
                builder: (context, eventSnapshot) {
                  if (eventSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (eventSnapshot.hasError) {
                    return Center(child: Text('Error: ${eventSnapshot.error}'));
                  } else if (!eventSnapshot.hasData || eventSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No events found'));
                  } else {
                    final events = eventSnapshot.data!;
                    final upcomingEvents = events.where((event) => DateTime.parse(event.dateTime).isAfter(DateTime.now())).toList();
                    final pastEvents = events.where((event) => DateTime.parse(event.dateTime).isBefore(DateTime.now())).toList();

                    return TabBarView(
                      children: [
                        _buildEventList(upcomingEvents, userTickets, context),
                        _buildEventList(pastEvents, userTickets, context),
                      ],
                    );
                  }
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildEventList(List<Event> events, List<UserEventTicket> userTickets, BuildContext context) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final ticketCount = userTickets.where((ticket) => ticket.eventId == event.id).length;
        return ListTile(
          title: Text(event.title),
          subtitle: Text(event.dateTime),
          trailing: Text('Tickets: $ticketCount'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventTicketsScreen(event: event),
              ),
            );
          },
        );
      },
    );
  }
}
