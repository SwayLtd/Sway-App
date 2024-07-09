import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';

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
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    _buildLinksRow(artist.links),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Follow/unfollow artist action
                      },
                      icon: Icon(artist.isFollowing ? Icons.check : Icons.add),
                      label: Text(artist.isFollowing ? 'Following' : 'Follow'),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "UPCOMING EVENTS",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...artist.upcomingEvents.map((eventId) {
                      return FutureBuilder<Event?>(
                        future: EventService().getEventById(eventId),
                        builder: (context, eventSnapshot) {
                          if (eventSnapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          } else if (eventSnapshot.hasError || !eventSnapshot.hasData || eventSnapshot.data == null) {
                            return const SizedBox.shrink(); // handle event not found case
                          } else {
                            final event = eventSnapshot.data!;
                            return ListTile(
                              title: Text(event.title),
                              subtitle: Text(event.dateTime),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EventScreen(event: event),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      "ABOUT",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(artist.description),
                    const SizedBox(height: 20),
                    const Text(
                      "MOOD",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8.0,
                      children: artist.genres.map((genreId) => GenreChip(genreId: genreId)).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "RESIDENT VENUES",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._buildResidentVenues(artist.id),
                    const SizedBox(height: 20),
                    const Text(
                      "FANS ALSO LIKE",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: artist.similarArtists.map((similarArtistId) {
                          return FutureBuilder<Artist?>(
                            future: ArtistService().getArtistById(similarArtistId),
                            builder: (context, similarArtistSnapshot) {
                              if (similarArtistSnapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator();
                              } else if (similarArtistSnapshot.hasError || !similarArtistSnapshot.hasData || similarArtistSnapshot.data == null) {
                                return const SizedBox.shrink(); // handle artist not found case
                              } else {
                                final similarArtist = similarArtistSnapshot.data!;
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ArtistScreen(artistId: similarArtist.id),
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
                                            imageUrl: similarArtist.imageUrl,
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

  Widget _buildLinksRow(Map<String, String> links) {
    final List<Widget> icons = [];
    links.forEach((platform, url) {
      IconData iconData;
      switch (platform) {
        case 'soundcloud':
          iconData = Icons.audiotrack;
          break;
        case 'spotify':
          iconData = Icons.music_note;
          break;
        case 'wikipedia':
          iconData = Icons.book;
          break;
        default:
          iconData = Icons.link;
      }
      icons.add(
        IconButton(
          icon: Icon(iconData),
          onPressed: () {
            // Open link action
          },
        ),
      );
    });
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: icons,
    );
  }

  List<Widget> _buildResidentVenues(String artistId) {
    return [
      FutureBuilder<List<Venue>>(
        future: VenueService().getVenues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Text('No venues found');
          } else {
            final venues = snapshot.data!;
            final residentVenues = venues.where((venue) => venue.residentArtists.contains(artistId)).toList();
            return Column(
              children: residentVenues.map((venue) {
                return ListTile(
                  title: Text(venue.name),
                  subtitle: Text(venue.location),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VenueScreen(venueId: venue.id),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          }
        },
      ),
    ];
  }
}
