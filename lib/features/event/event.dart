import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/common_section_widget.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';
import 'package:sway_events/features/event/services/event_genre_service.dart';
import 'package:sway_events/features/event/services/event_organizer_service.dart';
import 'package:sway_events/core/utils/date_utils.dart';
import 'package:sway_events/features/event/widgets/info_card.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';

class EventScreen extends StatelessWidget {
  final Event event;

  const EventScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    final DateTime eventDateTime = DateTime.parse(event.dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share event action
            },
          ),
          FutureBuilder<Map<String, bool>>(
            future: _getEventStatus(event.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: null,
                );
              } else if (snapshot.hasError) {
                return const IconButton(
                  icon: Icon(Icons.error),
                  onPressed: null,
                );
              } else {
                final bool isInterested =
                    snapshot.data?['isInterested'] ?? false;
                final bool isAttended = snapshot.data?['isAttended'] ?? false;
                return PopupMenuButton<String>(
                  icon: Icon(
                    isAttended
                        ? Icons.check_circle
                        : (isInterested
                            ? Icons.favorite
                            : Icons.favorite_border),
                  ),
                  onSelected: (String value) {
                    _handleMenuSelection(value, event.id, context);
                  },
                  itemBuilder: (BuildContext context) {
                    String notOptionText;
                    if (isAttended) {
                      notOptionText = 'Not going';
                    } else if (isInterested) {
                      notOptionText = 'Not interested';
                    } else {
                      notOptionText = 'Not interested';
                    }
                    return <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'interested',
                        child: Text('Interested'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'going',
                        child: Text('Going'),
                      ),
                      PopupMenuItem<String>(
                        value: 'ignored',
                        child: Text(notOptionText),
                      ),
                    ];
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: ImageWithErrorHandler(
                    imageUrl: event.imageUrl,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              FollowersCountWidget(entityId: event.id, entityType: 'event'),
              const SizedBox(height: 10),
              InfoCard(title: "Date", content: formatEventDate(eventDateTime)),
              FutureBuilder<Venue?>(
                future: VenueService().getVenueById(event.venue),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InfoCard(
                      title: "Location",
                      content: 'Loading...',
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const InfoCard(
                      title: "Location",
                      content: 'Location not found',
                    );
                  } else {
                    final venue = snapshot.data!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VenueScreen(venueId: venue.id),
                          ),
                        );
                      },
                      child: InfoCard(title: "Location", content: venue.name),
                    );
                  }
                },
              ),
              InfoCard(title: "Price", content: event.price),
              const SizedBox(height: 20),
              CommonSectionWidget(
                title: "DESCRIPTION",
                child: Text(event.description),
              ),
              const SizedBox(height: 20),
              CommonSectionWidget(
                title: "LINE UP",
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: FutureBuilder<List<Artist>>(
                    future: EventArtistService().getArtistsByEventId(event.id),
                    builder: (context, artistSnapshot) {
                      if (artistSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (artistSnapshot.hasError) {
                        return Text('Error: ${artistSnapshot.error}');
                      } else if (!artistSnapshot.hasData ||
                          artistSnapshot.data!.isEmpty) {
                        return const Text('No artists found');
                      } else {
                        final artists = artistSnapshot.data!;
                        return Row(
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
                                      borderRadius: BorderRadius.circular(10),
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
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CommonSectionWidget(
                title: "ORGANIZED BY",
                child: FutureBuilder<List<Organizer>>(
                  future:
                      EventOrganizerService().getOrganizersByEventId(event.id),
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
                            builder: (context, organizerDetailSnapshot) {
                              if (organizerDetailSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (organizerDetailSnapshot.hasError) {
                                return Text(
                                    'Error: ${organizerDetailSnapshot.error}');
                              } else if (!organizerDetailSnapshot.hasData ||
                                  organizerDetailSnapshot.data == null) {
                                return const Text(
                                    'Organizer details not found');
                              } else {
                                final detailedOrganizer =
                                    organizerDetailSnapshot.data!;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrganizerScreen(
                                            organizerId: detailedOrganizer.id),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: ImageWithErrorHandler(
                                          imageUrl: detailedOrganizer.imageUrl,
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),
                                      title: Text(
                                        detailedOrganizer.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FutureBuilder<int>(
                                            future:
                                                UserFollowOrganizerService()
                                                    .getOrganizerFollowersCount(
                                                        detailedOrganizer.id),
                                            builder: (context, countSnapshot) {
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
                                              "${detailedOrganizer.upcomingEvents.length} upcoming events"),
                                        ],
                                      ),
                                      trailing: FutureBuilder<bool>(
                                        future:
                                            UserFollowOrganizerService()
                                                .isFollowingOrganizer(
                                                    detailedOrganizer.id),
                                        builder:
                                            (context, followSnapshot) {
                                          if (followSnapshot
                                                  .connectionState ==
                                              ConnectionState.waiting) {
                                            return const CircularProgressIndicator();
                                          } else if (followSnapshot.hasError) {
                                            return Text(
                                                'Error: ${followSnapshot.error}');
                                          } else {
                                            final bool isFollowing =
                                                followSnapshot.data ?? false;
                                            return ElevatedButton(
                                              onPressed: () {
                                                if (isFollowing) {
                                                  UserFollowOrganizerService()
                                                      .unfollowOrganizer(
                                                          detailedOrganizer.id);
                                                } else {
                                                  UserFollowOrganizerService()
                                                      .followOrganizer(
                                                          detailedOrganizer.id);
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
              ),
              const SizedBox(height: 20),
              CommonSectionWidget(
                title: "MOOD",
                child: FutureBuilder<List<String>>(
                  future: EventGenreService().getGenresByEventId(event.id),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
              ),
              const SizedBox(height: 20),
              CommonSectionWidget(
                title: "LOCATION",
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VenueScreen(venueId: event.venue),
                      ),
                    );
                  },
                  child: FutureBuilder<Venue?>(
                    future: VenueService().getVenueById(event.venue),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const InfoCard(
                          title: "Location",
                          content: 'Loading...',
                        );
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data == null) {
                        return const InfoCard(
                          title: "Location",
                          content: 'Location not found',
                        );
                      } else {
                        final venue = snapshot.data!;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    VenueScreen(venueId: venue.id),
                              ),
                            );
                          },
                          child: InfoCard(
                            title: "Location",
                            content: venue.name,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Buy tickets action
        },
        label: const Text('BUY TICKETS'),
        icon: const Icon(Icons.shopping_cart),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<Map<String, bool>> _getEventStatus(String eventId) async {
    bool isInterested =
        await UserInterestEventService().isInterestedInEvent(eventId);
    bool isAttended = await UserInterestEventService().isAttendedEvent(eventId);
    return {'isInterested': isInterested, 'isAttended': isAttended};
  }

  void _handleMenuSelection(
      String value, String eventId, BuildContext context) {
    switch (value) {
      case 'interested':
        UserInterestEventService().addInterest(eventId);
        break;
      case 'going':
        UserInterestEventService().markEventAsAttended(eventId);
        break;
      case 'ignored':
        UserInterestEventService().removeInterest(eventId);
        break;
    }
    // Met à jour l'interface utilisateur en appelant setState
    (context as Element).markNeedsBuild();
  }
}
