// ticketing.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/ticketing/screens/event_tickets_screen.dart';

class TicketingScreen extends StatelessWidget {
  final EventService _eventService = EventService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Tickets"),
      ),
      body: FutureBuilder<List<Event>>(
        future: _eventService.getEvents(), // Replace with user's ticket fetching logic
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tickets found'));
          } else {
            final events = snapshot.data!;
            return ListView(
              children: events.map((event) => ListTile(
                title: Text(event.title),
                subtitle: Text(event.dateTime),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventTicketsScreen(event: event),
                    ),
                  );
                },
              )).toList(),
            );
          }
        },
      ),
    );
  }
}
