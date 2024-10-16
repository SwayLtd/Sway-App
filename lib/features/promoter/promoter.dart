// promoter.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/insight/insight.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/screens/edit_promoter_screen.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';

class PromoterScreen extends StatelessWidget {
  final int promoterId;

  const PromoterScreen({required this.promoterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promoter'),
        actions: [
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(promoterId, 'promoter', 'edit'),
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
                    final promoter =
                        await PromoterService().getPromoterById(promoterId);
                    if (promoter != null) {
                      final updatedPromoter = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditPromoterScreen(promoter: promoter),
                        ),
                      );
                      if (updatedPromoter != null) {
                        // Handle the updated promoter if necessary
                      }
                    }
                  },
                );
              }
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService().hasPermissionForCurrentUser(
              promoterId,
              'promoter',
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
                          entityId: promoterId,
                          entityType: 'promoter',
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
              final promoter =
                  await PromoterService().getPromoterById(promoterId);
              if (promoter != null) {
                shareEntity('promoter', promoterId, promoter.name);
              }
            },
          ),
          FollowingButtonWidget(
            entityId: promoterId,
            entityType: 'promoter',
          ),
        ],
      ),
      body: FutureBuilder<Promoter?>(
        future: PromoterService().getPromoterByIdWithEvents(promoterId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            debugPrint("Error loading promoter: ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            debugPrint("Promoter not found with ID: $promoterId");
            return const Center(child: Text('Promoter not found'));
          } else {
            final promoter = snapshot.data!;
            debugPrint("Displaying Promoter: ${promoter.id}");
            debugPrint(
              "Promoter upcoming events: ${promoter.upcomingEvents}",
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
                        imageUrl: promoter.imageUrl,
                        width: 200,
                        height: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    promoter.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  FollowersCountWidget(
                    entityId: promoterId,
                    entityType: 'promoter',
                  ),
                  const SizedBox(height: 5),
                  const SizedBox(height: 20),
                  const Text(
                    "UPCOMING EVENTS",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (promoter.upcomingEvents.isEmpty)
                    const Text('No upcoming events'),
                  ...promoter.upcomingEvents.map((eventId) {
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
                            subtitle: Text(formatEventDate(event.dateTime)),
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
                  Text(promoter.description),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
