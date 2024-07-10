import 'package:flutter/material.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/venue.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/user/services/user_follow_genre_service.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              // Share action with QR code
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit user profile action
            },
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: UserService().getUserById(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User not found'));
          } else {
            final user = snapshot.data!;
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
                          imageUrl: user.profilePictureUrl,
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.username,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Member since: ${user.createdAt.toLocal()}',
                      style: const TextStyle(
                          fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Genres',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Genre>>(
                      future: UserFollowGenreService()
                          .getFollowedGenresByUserId(userId),
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (genreSnapshot.hasError) {
                          return Text('Error: ${genreSnapshot.error}');
                        } else if (!genreSnapshot.hasData ||
                            genreSnapshot.data!.isEmpty) {
                          return const Text('No followed genres found');
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
                                          GenreScreen(genreId: genre.id),
                                    ),
                                  );
                                },
                                child: GenreChip(genreId: genre.id),
                              );
                            }).toList(),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Friends',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Placeholder for friends feature
                    const SizedBox(height: 20),
                    const Text(
                      'Artists',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Artist>>(
                      future: UserFollowArtistService()
                          .getFollowedArtistsByUserId(userId),
                      builder: (context, artistSnapshot) {
                        if (artistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (artistSnapshot.hasError) {
                          return Text('Error: ${artistSnapshot.error}');
                        } else if (!artistSnapshot.hasData ||
                            artistSnapshot.data!.isEmpty) {
                          return const Text('No followed artists found');
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
                      'Venues',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Venue>>(
                      future: UserFollowVenueService()
                          .getFollowedVenuesByUserId(userId),
                      builder: (context, venueSnapshot) {
                        if (venueSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (venueSnapshot.hasError) {
                          return Text('Error: ${venueSnapshot.error}');
                        } else if (!venueSnapshot.hasData ||
                            venueSnapshot.data!.isEmpty) {
                          return const Text('No followed venues found');
                        } else {
                          final venues = venueSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: venues.map((venue) {
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
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: ImageWithErrorHandler(
                                            imageUrl: venue.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(venue.name),
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
                      'Organizers',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Organizer>>(
                      future: UserFollowOrganizerService()
                          .getFollowedOrganizersByUserId(userId),
                      builder: (context, organizerSnapshot) {
                        if (organizerSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (organizerSnapshot.hasError) {
                          return Text('Error: ${organizerSnapshot.error}');
                        } else if (!organizerSnapshot.hasData ||
                            organizerSnapshot.data!.isEmpty) {
                          return const Text('No followed organizers found');
                        } else {
                          final organizers = organizerSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: organizers.map((organizer) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrganizerScreen(
                                            organizerId: organizer.id),
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
                                            imageUrl: organizer.imageUrl,
                                            width: 100,
                                            height: 100,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(organizer.name),
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
                      'Interested Events',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getInterestedEventsByUserId(userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          return Text('Error: ${eventSnapshot.error}');
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Text('No interested events found');
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
                      'Attended Events',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getAttendedEventsByUserId(userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (eventSnapshot.hasError) {
                          return Text('Error: ${eventSnapshot.error}');
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Text('No attended events found');
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
