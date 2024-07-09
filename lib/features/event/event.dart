import 'package:flutter/material.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/services/event_service.dart';
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
                  child: Image.network(
                    event.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                event.title,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildInfoCard(context, "Date", event.dateTime),
              FutureBuilder<Venue?>(
                future: VenueService().getVenueById(event.venue),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoCard(context, "Location", "Loading...");
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return _buildInfoCard(context, "Location", "Unknown");
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
                      child: _buildInfoCard(context, "Location", venue.name),
                    );
                  }
                },
              ),
              _buildInfoCard(context, "Price", event.price),
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
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          return Text('Artist not found');
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
                                    child: Image.network(
                                      artist.imageUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
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
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return SizedBox.shrink(); // handle organizer not found case
                      } else {
                        final organizer = snapshot.data!;
                        return ListTile(
                          title: Text(organizer.name),
                          subtitle: Text(
                            "${organizer.followers} followers\n${organizer.upcomingEvents.length} upcoming events",
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              organizer.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
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
                children: event.genres.map((genre) => Chip(label: Text(genre))).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                "LOCATION",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<Venue?>(
                future: VenueService().getVenueById(event.venue),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildInfoCard(context, "Location", "Loading...");
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return _buildInfoCard(context, "Location", "Unknown");
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
                      child: _buildInfoCard(context, "Location", venue.name),
                    );
                  }
                },
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

  Widget _buildInfoCard(BuildContext context, String title, String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(title),
        subtitle: GestureDetector(
          onTap: title == "Location"
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VenueScreen(venueId: content),
                    ),
                  );
                }
              : null,
          child: Text(content),
        ),
      ),
    );
  }
}
