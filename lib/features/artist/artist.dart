// lib/features/artist/artist.dart

import 'package:flutter/material.dart';

import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_genre_service.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/similar_artist_service.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_artist_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_resident_artists_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_resident_artists_service.dart';
import 'package:sway/features/venue/venue.dart';

class ArtistScreen extends StatefulWidget {
  final int artistId;

  const ArtistScreen({required this.artistId});

  @override
  _ArtistScreenState createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  String artistName = 'Artist';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$artistName Details'),
        actions: [
          FollowingButtonWidget(
            entityId: widget.artistId,
            entityType: 'artist',
          ),
        ],
      ),
      body: FutureBuilder<Artist?>(
        future: ArtistService().getArtistById(widget.artistId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Artist not found'));
          } else {
            final artist = snapshot.data!;
            artistName = artist.name; // Update the artist name
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary, // Couleur de la bordure
                            width: 2.0, // Épaisseur de la bordure
                          ),
                          borderRadius: BorderRadius.circular(
                              12), // Coins arrondis de la bordure
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ImageWithErrorHandler(
                            imageUrl: artist.imageUrl,
                            width: 200,
                            height: 200,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artist.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    FollowersCountWidget(
                      entityId: widget.artistId,
                      entityType: 'artist',
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: EventArtistService()
                          .getEventsByArtistId(widget.artistId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (eventSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${eventSnapshot.error}'),
                          );
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const SizedBox
                              .shrink(); // Hide section if empty
                        } else {
                          // Filtrer pour ne garder qu'un événement unique
                          final eventEntries = eventSnapshot.data!;
                          final uniqueEvents = eventEntries
                              .fold<Map<int, Event>>(
                                {},
                                (map, entry) {
                                  final event = entry['event'] as Event;
                                  map[event.id] = event;
                                  return map;
                                },
                              )
                              .values
                              .toList();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "UPCOMING EVENTS",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Column(
                                children: uniqueEvents.map((event) {
                                  return ListTile(
                                    title: Text(event.title),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${formatEventTime(event.dateTime)} - ${formatEventTime(event.endDateTime)}',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            FutureBuilder<Venue?>(
                                              future: EventVenueService()
                                                  .getVenueByEventId(event.id),
                                              builder:
                                                  (context, venueSnapshot) {
                                                if (venueSnapshot
                                                        .connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text(
                                                      'Loading...');
                                                } else if (venueSnapshot
                                                        .hasError ||
                                                    !venueSnapshot.hasData ||
                                                    venueSnapshot.data ==
                                                        null) {
                                                  return const Text(
                                                    'Venue not found',
                                                  );
                                                } else {
                                                  final venue =
                                                      venueSnapshot.data!;
                                                  return Text(venue.name);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                              ),
                            ],
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
                    FutureBuilder<List>(
                      future: ArtistGenreService()
                          .getGenresByArtistId(widget.artistId),
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (genreSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${genreSnapshot.error}'),
                          );
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
                    FutureBuilder<List<Promoter>>(
                      future: PromoterResidentArtistsService()
                          .getPromotersByArtistId(widget.artistId),
                      builder: (context, promoterSnapshot) {
                        if (promoterSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (promoterSnapshot.hasError) {
                          return Text('Error: ${promoterSnapshot.error}');
                        } else if (!promoterSnapshot.hasData ||
                            promoterSnapshot.data!.isEmpty) {
                          return const SizedBox
                              .shrink(); // Ne rien afficher si vide
                        } else {
                          final promoters = promoterSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "RESIDENT PROMOTERS",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: promoters.map((promoter) {
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PromoterScreen(
                                                    promoterId: promoter.id),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary, // Couleur de la bordure
                                                  width:
                                                      2.0, // Épaisseur de la bordure
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                    12), // Coins arrondis de la bordure
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: ImageWithErrorHandler(
                                                  imageUrl: promoter.imageUrl,
                                                  width: 100,
                                                  height: 100,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(promoter.name),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
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
                      future: VenueResidentArtistsService()
                          .getVenuesByArtistId(widget.artistId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const SizedBox
                              .shrink(); // Ne rien afficher si vide
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
                    FutureBuilder<List>(
                      future: SimilarArtistService()
                          .getSimilarArtistsByArtistId(widget.artistId),
                      builder: (context, similarArtistSnapshot) {
                        if (similarArtistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (similarArtistSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${similarArtistSnapshot.error}',
                            ),
                          );
                        } else if (!similarArtistSnapshot.hasData ||
                            similarArtistSnapshot.data!.isEmpty) {
                          return const Center(
                            child: Text('No similar artists found'),
                          );
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
                                      return const CircularProgressIndicator
                                          .adaptive();
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
                                                artistId: similarArtist.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary, // Couleur de la bordure
                                                    width:
                                                        2.0, // Épaisseur de la bordure
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12), // Coins arrondis de la bordure
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  child: ImageWithErrorHandler(
                                                    imageUrl:
                                                        similarArtist.imageUrl,
                                                    width: 100,
                                                    height: 100,
                                                  ),
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
