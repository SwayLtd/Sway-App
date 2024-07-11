import 'package:flutter/material.dart';
import 'package:sway_events/features/artist/services/artist_genre_service.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';
import 'package:sway_events/features/artist/services/similar_artist_service.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/user/widgets/follow_count_widget.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart'
    as followArtistService;

class ArtistScreen extends StatelessWidget {
  final String artistId;

  const ArtistScreen({required this.artistId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artist Details'),
      ),
      body: FutureBuilder<Artist?>(
        future: ArtistService().getArtistById(artistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Artist not found'));
          } else {
            final artist = snapshot.data!;
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
                          imageUrl: artist.imageUrl,
                          width: 200,
                          height: 200,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artist.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    FollowersCountWidget(entityId: artistId, entityType: 'artist'),
                    const SizedBox(height: 5),
                    FutureBuilder<bool>(
                      future: followArtistService.UserFollowArtistService()
                          .isFollowingArtist(artistId),
                      builder: (context, followSnapshot) {
                        if (followSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (followSnapshot.hasError) {
                          return Text('Error: ${followSnapshot.error}');
                        } else {
                          final bool isFollowing = followSnapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: () {
                              if (isFollowing) {
                                followArtistService.UserFollowArtistService()
                                    .unfollowArtist(artistId);
                              } else {
                                followArtistService.UserFollowArtistService()
                                    .followArtist(artistId);
                              }
                            },
                            child: Text(isFollowing ? "Following" : "Follow"),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "UPCOMING EVENTS",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Event>>(
                      future:
                          EventArtistService().getEventsByArtistId(artistId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${eventSnapshot.error}'));
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No upcoming events found'));
                        } else {
                          final events = eventSnapshot.data!;
                          return Column(
                            children: events.map((event) {
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
                            }).toList(),
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
                    Text(artist.description),
                    const SizedBox(height: 20),
                    const Text(
                      "MOOD",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<String>>(
                      future:
                          ArtistGenreService().getGenresByArtistId(artistId),
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (genreSnapshot.hasError) {
                          return Center(
                              child: Text('Error: ${genreSnapshot.error}'));
                        } else if (!genreSnapshot.hasData ||
                            genreSnapshot.data!.isEmpty) {
                          return const Center(child: Text('No genres found'));
                        } else {
                          final genres = genreSnapshot.data!;
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
                      "RESIDENT VENUES",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Venue>>(
                      future: VenueService().getVenuesByArtistId(artistId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No resident venues found'));
                        } else {
                          final venues = snapshot.data!;
                          return Column(
                            children: venues.map((venue) {
                              return ListTile(
                                title: Text(venue.name),
                                subtitle: Text(venue.location),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VenueScreen(venueId: venue.id),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "FANS ALSO LIKE",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<String>>(
                      future: SimilarArtistService()
                          .getSimilarArtistsByArtistId(artistId),
                      builder: (context, similarArtistSnapshot) {
                        if (similarArtistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (similarArtistSnapshot.hasError) {
                          return Center(
                              child: Text(
                                  'Error: ${similarArtistSnapshot.error}'));
                        } else if (!similarArtistSnapshot.hasData ||
                            similarArtistSnapshot.data!.isEmpty) {
                          return const Center(
                              child: Text('No similar artists found'));
                        } else {
                          final similarArtists = similarArtistSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: similarArtists.map((similarArtistId) {
                                return FutureBuilder<Artist?>(
                                  future: ArtistService()
                                      .getArtistById(similarArtistId),
                                  builder: (context, similarArtistSnapshot) {
                                    if (similarArtistSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    } else if (similarArtistSnapshot.hasError ||
                                        !similarArtistSnapshot.hasData ||
                                        similarArtistSnapshot.data == null) {
                                      return const SizedBox
                                          .shrink(); // handle artist not found case
                                    } else {
                                      final similarArtist =
                                          similarArtistSnapshot.data!;
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArtistScreen(
                                                      artistId:
                                                          similarArtist.id),
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
                                                  imageUrl:
                                                      similarArtist.imageUrl,
                                                  width: 100,
                                                  height: 100,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(similarArtist.name),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        }
                      },
                    ),
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
