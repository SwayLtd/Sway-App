import 'package:flutter/material.dart';
import 'package:sway_events/features/event/services/event_artist_service.dart';
import 'package:sway_events/features/event/services/event_genre_service.dart';
import 'package:sway_events/features/event/services/event_organizer_service.dart';
import 'package:sway_events/core/utils/date_utils.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/core/widgets/info_card.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
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
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              InfoCard(title: "Date", content: formatEventDate(eventDateTime)),
              FutureBuilder<Venue?>(
                future: VenueService().getVenueById(event.venue),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const InfoCard(
                        title: "Location", content: 'Loading...',);
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const InfoCard(
                        title: "Location", content: 'Location not found',);
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
                child: FutureBuilder<List<Artist>>(
                  future: EventArtistService().getArtistsByEventId(event.id),
                  builder: (context, artistSnapshot) {
                    if (artistSnapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (artistSnapshot.hasError) {
                      return Text('Error: ${artistSnapshot.error}');
                    } else if (!artistSnapshot.hasData || artistSnapshot.data!.isEmpty) {
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
              const SizedBox(height: 20),
              const Text(
                "OWNED BY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<Organizer>>(
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OrganizerScreen(organizerId: organizer.id),
                              ),
                            );
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),),
                            elevation: 2,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: ImageWithErrorHandler(
                                  imageUrl: organizer.imageUrl,
                                  width: 50,
                                  height: 50,
                                ),
                              ),
                              title: Text(organizer.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,),),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${organizer.followers} followers"),
                                  Text(
                                      "${organizer.upcomingEvents.length} upcoming events",),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  // Follow/unfollow organizer action
                                },
                                child: Text(organizer.isFollowing
                                    ? "Following"
                                    : "Follow",),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "MOOD",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<String>>(
                future: EventGenreService().getGenresByEventId(event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No genres found');
                  } else {
                    final genres = snapshot.data!;
                    return Wrap(
                      spacing: 8.0,
                      children: genres
                          .map((genreId) => GenreChip(genreId: genreId))
                          .toList(),
                    );
                  }
                },
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
                      return const InfoCard(
                          title: "Location", content: 'Loading...',);
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return const InfoCard(
                          title: "Location", content: 'Location not found',);
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
