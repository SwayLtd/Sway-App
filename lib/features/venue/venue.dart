// venue.dart

import 'package:flutter/material.dart';
import 'package:sway_events/core/utils/share_util.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/features/insight/insight.dart';
import 'package:sway_events/features/promoter/models/promoter_model.dart';
import 'package:sway_events/features/promoter/promoter.dart';
import 'package:sway_events/features/promoter/services/promoter_service.dart';
import 'package:sway_events/features/user/services/user_follow_promoter_service.dart';
import 'package:sway_events/features/user/services/user_permission_service.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/user/widgets/following_button_widget.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/screens/edit_venue_screen.dart';
import 'package:sway_events/features/venue/services/venue_genre_service.dart';
import 'package:sway_events/features/venue/services/venue_promoter_service.dart';
import 'package:sway_events/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class VenueScreen extends StatefulWidget {
  final String venueId;

  const VenueScreen({required this.venueId});

  @override
  _VenueScreenState createState() => _VenueScreenState();
}

class _VenueScreenState extends State<VenueScreen> {
  String venueName = 'Venue';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$venueName Details'),
        actions: [
          FutureBuilder<bool>(
            future: UserPermissionService()
                .hasPermissionForCurrentUser(widget.venueId, 'venue', 'edit'),
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
                    final venue =
                        await VenueService().getVenueById(widget.venueId);
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
            future: UserPermissionService().hasPermissionForCurrentUser(
                widget.venueId, 'venue', 'insight',),
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
                          entityId: widget.venueId,
                          entityType: 'venue',
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
            onPressed: () {
              shareEntity('venue', widget.venueId, venueName);
            },
          ),
          FollowingButtonWidget(
            entityId: widget.venueId,
            entityType: 'venue',
          ),
        ],
      ),
      body: FutureBuilder<Venue?>(
        future: VenueService().getVenueById(widget.venueId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Venue not found'));
          } else {
            final venue = snapshot.data!;
            venueName = venue.name; // Mettre à jour le nom du lieu
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
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FollowersCountWidget(
                      entityId: widget.venueId,
                      entityType: 'venue',
                    ),
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
                      "ABOUT",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      venue.description,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "OWNED BY",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Promoter>>(
                      future: VenuePromoterService()
                          .getPromotersByVenueId(venue.id),
                      builder: (context, promoterSnapshot) {
                        if (promoterSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (promoterSnapshot.hasError) {
                          return Text('Error: ${promoterSnapshot.error}');
                        } else if (!promoterSnapshot.hasData ||
                            promoterSnapshot.data!.isEmpty) {
                          return const Text('No promoters found');
                        } else {
                          final promoters = promoterSnapshot.data!;
                          return Column(
                            children: promoters.map((promoter) {
                              return FutureBuilder<Promoter?>(
                                future: PromoterService()
                                    .getPromoterByIdWithEvents(promoter.id),
                                builder:
                                    (context, promoterWithEventsSnapshot) {
                                  if (promoterWithEventsSnapshot
                                          .connectionState ==
                                      ConnectionState.waiting) {
                                    return const CircularProgressIndicator();
                                  } else if (promoterWithEventsSnapshot
                                      .hasError) {
                                    return Text(
                                      'Error: ${promoterWithEventsSnapshot.error}',
                                    );
                                  } else if (!promoterWithEventsSnapshot
                                          .hasData ||
                                      promoterWithEventsSnapshot.data ==
                                          null) {
                                    return const Text('Promoter not found');
                                  } else {
                                    final promoterWithEvents =
                                        promoterWithEventsSnapshot.data!;
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PromoterScreen(
                                              promoterId:
                                                  promoterWithEvents.id,
                                            ),
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
                                                  promoterWithEvents.imageUrl,
                                              width: 50,
                                              height: 50,
                                            ),
                                          ),
                                          title: Text(
                                            promoterWithEvents.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              FutureBuilder<int>(
                                                future: UserFollowPromoterService()
                                                    .getPromoterFollowersCount(
                                                  promoterWithEvents.id,
                                                ),
                                                builder:
                                                    (context, countSnapshot) {
                                                  if (countSnapshot
                                                          .connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Text(
                                                      'Loading followers...',
                                                    );
                                                  } else if (countSnapshot
                                                      .hasError) {
                                                    return Text(
                                                      'Error: ${countSnapshot.error}',
                                                    );
                                                  } else {
                                                    return Text(
                                                      '${countSnapshot.data} followers',
                                                    );
                                                  }
                                                },
                                              ),
                                              Text(
                                                "${promoterWithEvents.upcomingEvents.length} upcoming events",
                                              ),
                                            ],
                                          ),
                                          trailing: FutureBuilder<bool>(
                                            future: UserFollowPromoterService()
                                                .isFollowingPromoter(
                                              promoterWithEvents.id,
                                            ),
                                            builder: (context, followSnapshot) {
                                              if (followSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              } else if (followSnapshot
                                                  .hasError) {
                                                return Text(
                                                  'Error: ${followSnapshot.error}',
                                                );
                                              } else {
                                                final bool isFollowing =
                                                    followSnapshot.data ??
                                                        false;
                                                return ElevatedButton(
                                                  onPressed: () {
                                                    if (isFollowing) {
                                                      UserFollowPromoterService()
                                                          .unfollowPromoter(
                                                        promoterWithEvents.id,
                                                      );
                                                    } else {
                                                      UserFollowPromoterService()
                                                          .followPromoter(
                                                        promoterWithEvents.id,
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    isFollowing
                                                        ? "Following"
                                                        : "Follow",
                                                  ),
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
