import 'package:flutter/material.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/insight/insight.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart'
    as followOrganizerService;
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/user/widgets/following_button_widget.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/screens/edit_venue_screen.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/services/venue_genre_service.dart';
import 'package:sway_events/features/venue/services/venue_organizer_service.dart';
import 'package:sway_events/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';

class VenueScreen extends StatelessWidget {
  final String venueId;

  const VenueScreen({required this.venueId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venue Details'),
        actions: [
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(venueId, 'venue', 'edit'),
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
                    final venue = await VenueService().getVenueById(venueId);
                    if (venue != null) {
                      final updatedVenue = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditVenueScreen(venue: venue),
                        ),
                      );
                      if (updatedVenue != null) {
                        // Handle the updated venue if necessary
                      }
                    }
                  },
                );
              }
            },
          ),
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(venueId, 'venue', 'insight'),
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
                          entityId: venueId,
                          entityType: 'venue',
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Venue?>(
        future: VenueService().getVenueById(venueId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Venue not found'));
          } else {
            final venue = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: ImageWithErrorHandler(
                          imageUrl: venue.imageUrl,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      venue.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FollowersCountWidget(
                        entityId: venueId, entityType: 'venue'),
                    FollowingButtonWidget(
                        entityId: venueId, entityType: 'venue'),
                    const SizedBox(height: 20),
                    const Text(
                      "RESIDENT ARTISTS",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Artist>>(
                      future: VenueResidentArtistsService()
                          .getArtistsByVenueId(venue.id),
                      builder: (context, artistSnapshot) {
                        if (artistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (artistSnapshot.hasError) {
                          return Text('Error: ${artistSnapshot.error}');
                        } else if (!artistSnapshot.hasData ||
                            artistSnapshot.data!.isEmpty) {
                          return const Text('No resident artists found');
                        } else {
                          final artists = artistSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: artists.map((artist) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ArtistScreen(artistId: artist.id),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ImageWithErrorHandler(
                                            imageUrl: artist.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(artist.name),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "OWNED BY",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Organizer>>(
                      future: VenueOrganizerService()
                          .getOrganizersByVenueId(venue.id),
                      builder: (context, organizerSnapshot) {
                        if (organizerSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (organizerSnapshot.hasError) {
                          return Text('Error: ${organizerSnapshot.error}');
                        } else if (!organizerSnapshot.hasData ||
                            organizerSnapshot.data!.isEmpty) {
                          return const Text('No organizers found');
                        } else {
                          final organizers = organizerSnapshot.data!;
                          return Column(
                            children: organizers.map((organizer) {
                              return FutureBuilder<Organizer?>(
                                future: OrganizerService()
                                    .getOrganizerByIdWithEvents(organizer.id),
                                builder:
                                    (context, organizerWithEventsSnapshot) {
                                  if (organizerWithEventsSnapshot
                                          .connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (organizerWithEventsSnapshot
                                      .hasError) {
                                    return Text(
                                        'Error: ${organizerWithEventsSnapshot.error}');
                                  } else if (!organizerWithEventsSnapshot
                                          .hasData ||
                                      organizerWithEventsSnapshot.data ==
                                          null) {
                                    return const Text('Organizer not found');
                                  } else {
                                    final organizerWithEvents =
                                        organizerWithEventsSnapshot.data!;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                OrganizerScreen(
                                                    organizerId:
                                                        organizerWithEvents.id),
                                          ),
                                        );
                                      },
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        elevation: 2,
                                        child: ListTile(
                                          leading: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: ImageWithErrorHandler(
                                              imageUrl:
                                                  organizerWithEvents.imageUrl,
                                              width: 50,
                                              height: 50,
                                            ),
                                          ),
                                          title: Text(
                                            organizerWithEvents.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<int>(
                                                future: followOrganizerService
                                                        .UserFollowOrganizerService()
                                                    .getOrganizerFollowersCount(
                                                        organizerWithEvents.id),
                                                builder:
                                                    (context, countSnapshot) {
                                                  if (countSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Text(
                                                        'Loading followers...');
                                                  } else if (countSnapshot
                                                      .hasError) {
                                                    return Text(
                                                        'Error: ${countSnapshot.error}');
                                                  } else {
                                                    return Text(
                                                        '${countSnapshot.data} followers');
                                                  }
                                                },
                                              ),
                                              Text(
                                                  "${organizerWithEvents.upcomingEvents.length} upcoming events"),
                                            ],
                                          ),
                                          trailing: FutureBuilder<bool>(
                                            future: followOrganizerService
                                                    .UserFollowOrganizerService()
                                                .isFollowingOrganizer(
                                                    organizerWithEvents.id),
                                            builder: (context, followSnapshot) {
                                              if (followSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              } else if (followSnapshot
                                                  .hasError) {
                                                return Text(
                                                    'Error: ${followSnapshot.error}');
                                              } else {
                                                final bool isFollowing =
                                                    followSnapshot.data ??
                                                        false;
                                                return ElevatedButton(
                                                  onPressed: () {
                                                    if (isFollowing) {
                                                      followOrganizerService
                                                              .UserFollowOrganizerService()
                                                          .unfollowOrganizer(
                                                              organizerWithEvents
                                                                  .id);
                                                    } else {
                                                      followOrganizerService
                                                              .UserFollowOrganizerService()
                                                          .followOrganizer(
                                                              organizerWithEvents
                                                                  .id);
                                                    }
                                                  },
                                                  child: Text(isFollowing
                                                      ? "Following"
                                                      : "Follow"),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "MOOD",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<String>>(
                      future: VenueGenreService().getGenresByVenueId(venue.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No genres found');
                        } else {
                          final genres = snapshot.data!;
                          return Wrap(
                            spacing: 8.0,
                            children: genres.map((genre) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GenreScreen(genreId: genre),
                                    ),
                                  );
                                },
                                child: GenreChip(genreId: genre),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "LOCATION",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(venue.location),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
