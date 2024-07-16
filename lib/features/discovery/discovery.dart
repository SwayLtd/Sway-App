// discovery.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/artist/services/similar_artist_service.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/event/widgets/event_card.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/features/notification/notification.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_follow_artist_service.dart';
import 'package:sway_events/features/user/services/user_follow_genre_service.dart';
import 'package:sway_events/features/user/services/user_follow_organizer_service.dart';
import 'package:sway_events/features/user/services/user_follow_venue_service.dart';
import 'package:sway_events/features/user/services/user_service.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/venue.dart';

class DiscoveryScreen extends StatelessWidget {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final UserFollowArtistService _userFollowArtistService =
      UserFollowArtistService();
  final UserFollowGenreService _userFollowGenreService =
      UserFollowGenreService();
  final UserFollowOrganizerService _userFollowOrganizerService =
      UserFollowOrganizerService();
  final UserFollowVenueService _userFollowVenueService =
      UserFollowVenueService();
  final SimilarArtistService _similarArtistService = SimilarArtistService();
  final int unreadNotifications = 5; // Number of unread notifications

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Discovery"),
        actions: [
          IconButton(
            icon: Stack(
              children: <Widget>[
                const Icon(Icons.notifications),
                if (unreadNotifications > 0)
                  Positioned(
                    right: 0,
                    child: Badge(), // Keep Badge empty as per your requirement
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: _userService.getCurrentUser(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          } else if (!userSnapshot.hasData) {
            return const Center(child: Text('No user found'));
          } else {
            final user = userSnapshot.data!;
            return FutureBuilder<Map<String, dynamic>>(
              future: _fetchUserRecommendations(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('No recommendations found'));
                } else {
                  final recommendations = snapshot.data!;
                  return ListView(
                    children: [
                      if ((recommendations['events'] as List<Event>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Upcoming Events'),
                        ..._buildEventCards(
                          context,
                          recommendations['events'] as List<Event>,
                        ),
                      ],
                      if ((recommendations['organizers'] as List<Organizer>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Suggested Organizers'),
                        ..._buildOrganizerCards(
                          context,
                          recommendations['organizers'] as List<Organizer>,
                        ),
                      ],
                      if ((recommendations['artists'] as List<Artist>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Suggested Artists'),
                        ..._buildArtistCards(
                          context,
                          recommendations['artists'] as List<Artist>,
                        ),
                      ],
                      if ((recommendations['venues'] as List<Venue>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Suggested Venues'),
                        ..._buildVenueCards(
                          context,
                          recommendations['venues'] as List<Venue>,
                        ),
                      ],
                      if ((recommendations['genres'] as List<Genre>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Suggested Genres'),
                        _buildGenreChips(
                          context,
                          recommendations['genres'] as List<Genre>,
                        ),
                      ],
                    ],
                  );
                }
              },
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchUserRecommendations(String userId) async {
    final followedArtists =
        await _userFollowArtistService.getFollowedArtistsByUserId(userId);
    final followedGenres =
        await _userFollowGenreService.getFollowedGenresByUserId(userId);
    final followedOrganizers =
        await _userFollowOrganizerService.getFollowedOrganizersByUserId(userId);
    final followedVenues =
        await _userFollowVenueService.getFollowedVenuesByUserId(userId);

    final similarArtists = <Artist>[];
    for (final artist in followedArtists) {
      final similarArtistIds =
          await _similarArtistService.getSimilarArtistsByArtistId(artist.id);
      final allArtists = await ArtistService().getArtists();
      final similar =
          allArtists.where((a) => similarArtistIds.contains(a.id)).toList();
      similarArtists.addAll(similar);
    }

    final upcomingEvents = await _eventService.getEvents();
    final now = DateTime.now();
    final filteredEvents = upcomingEvents.where((event) {
      final eventDate = DateTime.parse(event.dateTime);
      final isFutureEvent = eventDate.isAfter(now);
      final matchesGenre =
          followedGenres.any((genre) => event.genres.contains(genre.id));
      final matchesArtist =
          followedArtists.any((artist) => event.artists.contains(artist.id));
      final matchesVenue =
          followedVenues.any((venue) => event.venue == venue.id);
      final matchesOrganizer = followedOrganizers
          .any((organizer) => event.organizers.contains(organizer.id));
      return isFutureEvent &&
          (matchesGenre || matchesArtist || matchesVenue || matchesOrganizer);
    }).toList();

    return {
      'events': filteredEvents.take(5).toList(),
      'artists': similarArtists.take(5).toList(),
      'genres': followedGenres.take(5).toList(),
      'organizers': followedOrganizers.take(5).toList(),
      'venues': followedVenues.take(5).toList(),
    };
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  List<Widget> _buildEventCards(BuildContext context, List<Event> events) {
    return events
        .map<Widget>(
          (event) => EventCard(event: event),
        )
        .toList();
  }

  List<Widget> _buildOrganizerCards(
    BuildContext context,
    List<Organizer> organizers,
  ) {
    return organizers
        .map<Widget>(
          (organizer) => ListTile(
            title: Text(organizer.name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrganizerScreen(
                    organizerId: organizer.id,
                  ),
                ),
              );
            },
          ),
        )
        .toList();
  }

  List<Widget> _buildArtistCards(BuildContext context, List<Artist> artists) {
    return artists
        .map<Widget>(
          (artist) => ListTile(
            title: Text(artist.name),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArtistScreen(artistId: artist.id),
                ),
              );
            },
          ),
        )
        .toList();
  }

  List<Widget> _buildVenueCards(BuildContext context, List<Venue> venues) {
    return venues
        .map<Widget>(
          (venue) => ListTile(
            title: Text(venue.name),
            subtitle: Text(venue.location),
            leading: const Icon(Icons.location_on),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VenueScreen(venueId: venue.id),
                ),
              );
            },
          ),
        )
        .toList();
  }

  Widget _buildGenreChips(BuildContext context, List<Genre> genres) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 8.0,
            children: genres
                .map(
                  (genre) => GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GenreScreen(genreId: genre.id),
                        ),
                      );
                    },
                    child: GenreChip(genreId: genre.id),
                  ),
                )
                .toList(),
          ),
        ));
  }
}

class Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: const Text(
        '5', // Replace with the actual number of unread notifications
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
