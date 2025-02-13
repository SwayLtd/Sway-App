// lib/features/user/screens/user_entities_screen.dart

import 'package:flutter/material.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/screens/edit_event_screen.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/screens/edit_promoter_screen.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_permission_model.dart';
import 'package:sway/features/user/services/user_permission_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/screens/edit_venue_screen.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';

// Nouveaux imports pour les artistes
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/screens/edit_artist_screen.dart';
import 'package:sway/features/artist/services/artist_service.dart';

class UserEntitiesScreen extends StatelessWidget {
  final int userId;

  const UserEntitiesScreen({required this.userId});

  Future<List<UserPermission>> _getPermissions(String entityType) async {
    return await UserPermissionService()
        .getPermissionsByUserIdAndType(userId, entityType);
  }

  Future<void> _navigateToEntity(
    BuildContext context,
    String entityType,
    int entityId,
  ) async {
    switch (entityType) {
      case 'event':
        final event = await EventService().getEventById(entityId);
        if (event != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventScreen(event: event)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Event not found')),
          );
        }
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(entityId);
        if (venue != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VenueScreen(venueId: venue.id!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Venue not found')),
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
              builder: (context) => PromoterScreen(promoterId: promoter.id!),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Promoter not found')),
          );
        }
        break;
      case 'artist': // Nouveau cas pour les artistes
        final artist = await ArtistService().getArtistById(entityId);
        if (artist != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ArtistScreen(artistId: artist.id!)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Artist not found')),
          );
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Unknown entity type')),
        );
    }
  }

  Future<void> _editEntity(
    BuildContext context,
    String entityType,
    int entityId,
  ) async {
    switch (entityType) {
      case 'event':
        final event = await EventService().getEventById(entityId);
        if (event != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEventScreen(event: event),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Event not found')),
          );
        }
        break;
      case 'venue':
        final venue = await VenueService().getVenueById(entityId);
        if (venue != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditVenueScreen(venue: venue),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Venue not found')),
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
              builder: (context) => EditPromoterScreen(promoter: promoter),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Promoter not found')),
          );
        }
        break;
      case 'artist': // Nouveau cas pour les artistes
        final artist = await ArtistService().getArtistById(entityId);
        if (artist != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditArtistScreen(artist: artist),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Artist not found')),
          );
        }
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Unknown entity type')),
        );
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
            // Events Section
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
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
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
                            return const CircularProgressIndicator.adaptive();
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
            // Venues Section
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
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
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
                            return const CircularProgressIndicator.adaptive();
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
            // Promoters Section
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
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
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
                            return const CircularProgressIndicator.adaptive();
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
            // Artists Section
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Artists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            FutureBuilder<List<UserPermission>>(
              future: _getPermissions('artist'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator.adaptive());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No artists found'));
                } else {
                  final artistPermissions = snapshot.data!;
                  return Column(
                    children: artistPermissions.map((permission) {
                      return FutureBuilder<Artist?>(
                        future:
                            ArtistService().getArtistById(permission.entityId),
                        builder: (context, artistSnapshot) {
                          if (artistSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator.adaptive();
                          } else if (artistSnapshot.hasError ||
                              !artistSnapshot.hasData) {
                            return const SizedBox.shrink();
                          } else {
                            final artist = artistSnapshot.data!;
                            return ListTile(
                              title: Text(artist.name),
                              subtitle: Text('Role: ${permission.permission}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editEntity(
                                    context, 'artist', permission.entityId),
                              ),
                              onTap: () => _navigateToEntity(
                                  context, 'artist', permission.entityId),
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
