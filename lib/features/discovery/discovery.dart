// discovery.dart

import 'package:flutter/material.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/similar_artist_service.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/widgets/event_card.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/notification/notification.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';

class DiscoveryScreen extends StatelessWidget {
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final UserFollowArtistService _userFollowArtistService =
      UserFollowArtistService();
  final UserFollowGenreService _userFollowGenreService =
      UserFollowGenreService();
  final UserFollowPromoterService _userFollowPromoterService =
      UserFollowPromoterService();
  final UserFollowVenueService _userFollowVenueService =
      UserFollowVenueService();
  final SimilarArtistService _similarArtistService = SimilarArtistService();
  final UserInterestEventService _userInterestEventService =
      UserInterestEventService();
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildEventCards(
                              context,
                              recommendations['events'] as List<Event>,
                            ),
                          ),
                        ),
                      ],
                      if ((recommendations['promoters'] as List<Promoter>)
                          .isNotEmpty) ...[
                        _buildSectionTitle('Suggested Promoters'),
                        ..._buildPromoterCards(
                          context,
                          recommendations['promoters'] as List<Promoter>,
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

  Future<Map<String, dynamic>> _fetchUserRecommendations(int userId) async {
    final followedArtists =
        await _userFollowArtistService.getFollowedArtistsByUserId(userId);
    final followedGenres =
        await _userFollowGenreService.getFollowedGenresByUserId(userId);
    final followedPromoters =
        await _userFollowPromoterService.getFollowedPromotersByUserId(userId);
    final followedVenues =
        await _userFollowVenueService.getFollowedVenuesByUserId(userId);
    final interestedEvents =
        await _userInterestEventService.getInterestedEventsByUserId(userId);
    final goingEvents =
        await _userInterestEventService.getGoingEventsByUserId(userId);

    final followedArtistIds =
        followedArtists.map((artist) => artist.id).toList();
    final followedGenreIds = followedGenres.map((genre) => genre.id).toList();
    final followedPromoterIds =
        followedPromoters.map((promoter) => promoter.id).toList();
    final followedVenueIds = followedVenues.map((venue) => venue.id).toList();
    final followedEventIds =
        interestedEvents.map((event) => event.id).toList() +
            goingEvents.map((event) => event.id).toList();

    final similarArtists = <Artist>{};
    for (final artist in followedArtists) {
      final similarArtistIds =
          await _similarArtistService.getSimilarArtistsByArtistId(artist.id);
      final allArtists = await ArtistService().getArtists();
      final similar = allArtists
          .where(
            (a) =>
                similarArtistIds.contains(a.id) &&
                !followedArtistIds.contains(a.id),
          )
          .toList();
      similarArtists.addAll(similar);
    }

    final upcomingEvents = await _eventService.getEvents();
    final now = DateTime.now();
    final filteredEvents = upcomingEvents.where((event) {
      final eventDate = event.dateTime;
      final isFutureEvent = eventDate.isAfter(now);
      final isToday = eventDate.day == now.day &&
          eventDate.month == now.month &&
          eventDate.year == now.year;
      final matchesGenre =
          event.genres.any((genreId) => followedGenreIds.contains(genreId));
      final matchesArtist =
          event.artists.any((artistId) => followedArtistIds.contains(artistId));
      final matchesVenue = followedVenueIds.contains(event.venue);
      final matchesPromoter = event.promoters
          .any((promoterId) => followedPromoterIds.contains(promoterId));
      final isNotFollowedEvent = !followedEventIds.contains(event.id);
      return (isToday || isFutureEvent) &&
          (matchesGenre || matchesArtist || matchesVenue || matchesPromoter) &&
          isNotFollowedEvent;
    }).toList();

    final allArtists = await ArtistService().getArtists();
    final allGenres = await GenreService().getGenres();
    final allPromoters = await PromoterService().getPromoters();
    final allVenues = await VenueService().getVenues();

    final suggestedArtists = allArtists
        .where((artist) => !followedArtistIds.contains(artist.id))
        .take(3)
        .toList();
    final suggestedGenres = allGenres
        .where((genre) => !followedGenreIds.contains(genre.id))
        .take(3)
        .toList();
    final suggestedPromoters = allPromoters
        .where((promoter) => !followedPromoterIds.contains(promoter.id))
        .take(3)
        .toList();
    final suggestedVenues = allVenues
        .where((venue) => !followedVenueIds.contains(venue.id))
        .take(3)
        .toList();

    return {
      'events': filteredEvents.take(5).toList(),
      'artists': {...similarArtists.take(3), ...suggestedArtists}.toList(),
      'genres': suggestedGenres,
      'promoters': suggestedPromoters,
      'venues': suggestedVenues,
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
    return [
      SizedBox(
        // height: 375, // Adjust height as needed
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: events.map<Widget>((event) {
              return Container(
                width: 400, // Adjust width as needed
                margin: const EdgeInsets.only(right: 10),
                child: EventCard(event: event),
              );
            }).toList(),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildPromoterCards(
    BuildContext context,
    List<Promoter> promoters,
  ) {
    return promoters
        .map<Widget>(
          (promoter) => ListTile(
            title: Text(promoter.name),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: ImageWithErrorHandler(
                  imageUrl: promoter.imageUrl,
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PromoterScreen(promoterId: promoter.id),
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
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ImageWithErrorHandler(
                imageUrl: artist.imageUrl,
                width: 50,
                height: 50,
              ),
            ),
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
            subtitle: Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(venue.location),
              ],
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ImageWithErrorHandler(
                imageUrl: venue.imageUrl,
                width: 50,
                height: 50,
              ),
            ),
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
      ),
    );
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
