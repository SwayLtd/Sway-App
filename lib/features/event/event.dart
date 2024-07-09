import 'package:flutter/material.dart';
import 'package:sway_events/core/utils/date_utils.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/core/widgets/info_card.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';

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
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // Like event action
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              InfoCard(title: "Date", content: formatEventDate(eventDateTime)),
              FutureBuilder<Venue?>(
                future: VenueService().getVenueById(event.venue),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InfoCard(title: "Location", content: 'Loading...');
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const InfoCard(title: "Location", content: 'Location not found');
                  } else {
                    final venue = snapshot.data!;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VenueScreen(venueId: venue.id),
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
              const Text(
                "DESCRIPTION",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(event.description),
              const SizedBox(height: 20),
              const Text(
                "LINE UP",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: event.lineup.map((artistId) {
                    return FutureBuilder<Artist>(
                      future: ArtistService().getArtistById(artistId).then((artist) {
                        if (artist == null) {
                          throw Exception('Artist not found');
                        }
                        return artist;
                      }),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          return const Text('Artist not found');
                        } else {
                          final artist = snapshot.data!;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArtistScreen(artistId: artist.id),
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
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "ORGANIZED BY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                children: event.organizers.map((organizerId) {
                  return FutureBuilder<Organizer?>(
                    future: OrganizerService().getOrganizerById(organizerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      } else {
                        final organizer = snapshot.data!;
                        return ListTile(
                          title: Text(organizer.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${organizer.followers} followers"),
                              Text("${organizer.upcomingEvents.length} upcoming events"),
                            ],
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: ImageWithErrorHandler(
                              imageUrl: organizer.imageUrl,
                              width: 50,
                              height: 50,
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Follow/unfollow organizer action
                            },
                            child: Text(organizer.isFollowing ? "Following" : "Follow"),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrganizerScreen(organizerId: organizer.id),
                              ),
                            );
                          },
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                "MOOD",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                children: event.genres.map((genreId) => GenreChip(genreId: genreId)).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                "LOCATION",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
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
                      return const InfoCard(title: "Location", content: 'Loading...');
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return const InfoCard(title: "Location", content: 'Location not found');
                    } else {
                      final venue = snapshot.data!;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VenueScreen(venueId: venue.id),
                            ),
                          );
                        },
                        child: InfoCard(title: "Location", content: venue.name),
                      );
                    }
                  },
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
}
