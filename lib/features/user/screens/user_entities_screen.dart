import 'package:flutter/material.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/screens/edit_event_screen.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/promoter.dart';
import 'package:sway_events/features/promoter/screens/edit_promoter_screen.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';
import 'package:sway_events/features/user/models/user_permission_model.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/screens/edit_venue_screen.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';

class UserEntitiesScreen extends StatelessWidget {
  final String userId;

  const UserEntitiesScreen({required this.userId});

  Future<List<UserPermission>> _getPermissions(String entityType) async {
    return await UserPermissionService()
        .getPermissionsByUserIdAndType(userId, entityType);
  }

  void _navigateToEntity(
      BuildContext context, String entityType, String entityId) async {
    switch (entityType) {
      case 'event':
        final event = await EventService().getEventById(entityId);
        if (event != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventScreen(event: event)),
          );
        }
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(entityId);
        if (venue != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VenueScreen(venueId: venue.id)),
          );
        }
        break;
      case 'promoter':
        final promoter =
            await PromoterService().getPromoterByIdWithEvents(entityId);
        if (promoter != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    PromoterScreen(promoterId: promoter.id)),
          );
        }
        break;
    }
  }

  void _editEntity(
      BuildContext context, String entityType, String entityId) async {
    switch (entityType) {
      case 'event':
        final event = await EventService().getEventById(entityId);
        if (event != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditEventScreen(event: event)),
          );
        }
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(entityId);
        if (venue != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditVenueScreen(venue: venue)),
          );
        }
        break;
      case 'promoter':
        final promoter =
            await PromoterService().getPromoterByIdWithEvents(entityId);
        if (promoter != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditPromoterScreen(promoter: promoter)),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Entities'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Events',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<UserPermission>>(
              future: _getPermissions('event'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No events found'));
                } else {
                  final eventPermissions = snapshot.data!;
                  return Column(
                    children: eventPermissions.map((permission) {
                      return FutureBuilder<Event?>(
                        future:
                            EventService().getEventById(permission.entityId),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (eventSnapshot.hasError ||
                              !eventSnapshot.hasData) {
                            return const SizedBox.shrink();
                          } else {
                            final event = eventSnapshot.data!;
                            return ListTile(
                              title: Text(event.title),
                              subtitle: Text('Role: ${permission.permission}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editEntity(
                                    context, 'event', permission.entityId),
                              ),
                              onTap: () => _navigateToEntity(
                                  context, 'event', permission.entityId),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Venues',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<UserPermission>>(
              future: _getPermissions('venue'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No venues found'));
                } else {
                  final venuePermissions = snapshot.data!;
                  return Column(
                    children: venuePermissions.map((permission) {
                      return FutureBuilder<Venue?>(
                        future:
                            VenueService().getVenueById(permission.entityId),
                        builder: (context, venueSnapshot) {
                          if (venueSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (venueSnapshot.hasError ||
                              !venueSnapshot.hasData) {
                            return const SizedBox.shrink();
                          } else {
                            final venue = venueSnapshot.data!;
                            return ListTile(
                              title: Text(venue.name),
                              subtitle: Text('Role: ${permission.permission}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editEntity(
                                    context, 'venue', permission.entityId),
                              ),
                              onTap: () => _navigateToEntity(
                                  context, 'venue', permission.entityId),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Promoters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<UserPermission>>(
              future: _getPermissions('promoter'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No promoters found'));
                } else {
                  final promoterPermissions = snapshot.data!;
                  return Column(
                    children: promoterPermissions.map((permission) {
                      return FutureBuilder<Promoter?>(
                        future: PromoterService()
                            .getPromoterByIdWithEvents(permission.entityId),
                        builder: (context, promoterSnapshot) {
                          if (promoterSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (promoterSnapshot.hasError ||
                              !promoterSnapshot.hasData) {
                            return const SizedBox.shrink();
                          } else {
                            final promoter = promoterSnapshot.data!;
                            return ListTile(
                              title: Text(promoter.name),
                              subtitle: Text('Role: ${permission.permission}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editEntity(
                                    context, 'promoter', permission.entityId),
                              ),
                              onTap: () => _navigateToEntity(
                                  context, 'promoter', permission.entityId),
                            );
                          }
                        },
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
