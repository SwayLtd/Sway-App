// organizer.dart

import 'package:flutter/material.dart';
import 'package:sway_events/core/utils/share_util.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/insight/insight.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/screens/edit_organizer_screen.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/user/widgets/following_button_widget.dart';

class OrganizerScreen extends StatelessWidget {
  final String organizerId;

  const OrganizerScreen({required this.organizerId});

  @override
  Widget build(BuildContext context) {
    debugPrint("OrganizerScreen opened with ID: $organizerId");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer'),
        actions: [
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(organizerId, 'organizer', 'edit'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final organizer =
                        await OrganizerService().getOrganizerById(organizerId);
                    if (organizer != null) {
                      final updatedOrganizer = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditOrganizerScreen(organizer: organizer),
                        ),
                      );
                      if (updatedOrganizer != null) {
                        // Handle the updated organizer if necessary
                      }
                    }
                  },
                );
              }
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              organizerId,
              'organizer',
              'insight',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  !snapshot.data!) {
                return const SizedBox.shrink();
              } else {
                return IconButton(
                  icon: const Icon(Icons.insights),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InsightScreen(
                          entityId: organizerId,
                          entityType: 'organizer',
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final organizer =
                  await OrganizerService().getOrganizerById(organizerId);
              if (organizer != null) {
                shareEntity('organizer', organizerId, organizer.name);
              }
            },
          ),
          FollowingButtonWidget(
            entityId: organizerId,
            entityType: 'organizer',
          ),
        ],
      ),
      body: FutureBuilder<Organizer?>(
        future: OrganizerService().getOrganizerByIdWithEvents(organizerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint("Error loading organizer: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            debugPrint("Organizer not found with ID: $organizerId");
            return const Center(child: Text('Organizer not found'));
          } else {
            final organizer = snapshot.data!;
            debugPrint("Displaying Organizer: ${organizer.id}");
            debugPrint(
              "Organizer upcoming events: ${organizer.upcomingEvents}",
            );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: ImageWithErrorHandler(
                        imageUrl: organizer.imageUrl,
                        width: 200,
                        height: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    organizer.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FollowersCountWidget(
                    entityId: organizerId,
                    entityType: 'organizer',
                  ),
                  const SizedBox(height: 5),
                  const SizedBox(height: 20),
                  const Text(
                    "UPCOMING EVENTS",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (organizer.upcomingEvents.isEmpty)
                    const Text('No upcoming events'),
                  ...organizer.upcomingEvents.map((eventId) {
                    debugPrint("Loading event with ID: $eventId");
                    return FutureBuilder<Event?>(
                      future: EventService().getEventById(eventId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          debugPrint(
                            "Error loading event with ID $eventId: ${eventSnapshot.error}",
                          );
                          return const SizedBox
                              .shrink(); // handle event not found case
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data == null) {
                          debugPrint("Event not found with ID: $eventId");
                          return const SizedBox
                              .shrink(); // handle event not found case
                        } else {
                          final event = eventSnapshot.data!;
                          debugPrint("Displaying event: ${event.title}");
                          return ListTile(
                            title: Text(event.title),
                            subtitle: Text(event.dateTime),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EventScreen(event: event),
                                ),
                              );
                            },
                          );
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  const Text(
                    "ABOUT",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(organizer.description),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
