// discovery.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/event/widgets/event_card.dart';
import 'package:sway_events/features/notification/notification.dart';

class DiscoveryScreen extends StatelessWidget {
  final int unreadNotifications = 5; // Number of unread notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery"),
        actions: [
          IconButton(
            icon: Stack(
              children: <Widget>[
                const Icon(Icons.notifications),
                if (unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    child: Badge(), // Keep Badge empty as per your requirement
                  )
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Event>>(
        future: EventService().getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No events found'));
          } else {
            final now = DateTime.now();
            final events = (snapshot.data ?? [])
                .where((event) => DateTime.parse(event.dateTime).isAfter(now))
                .toList();
            return ListView(
              children: events.map((event) => EventCard(event: event)).toList(),
            );
          }
        },
      ),
    );
  }
}

class Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: const Text(
        '5', // Replace with the actual number of unread notifications
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
