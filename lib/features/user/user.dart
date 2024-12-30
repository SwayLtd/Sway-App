// user.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/utils/share_util.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/follow_count_widget.dart';
import 'package:sway/features/user/widgets/following_button_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/venue.dart';

class UserScreen extends StatelessWidget {
  final int userId;

  const UserScreen({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          // Bouton de Partage
          FutureBuilder<User?>(
            future: UserService().getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Afficher rien pendant le chargement
                return const SizedBox.shrink();
              } else if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                // Afficher rien en cas d'erreur ou si l'utilisateur n'est pas trouvé
                return const SizedBox.shrink();
              } else {
                final user = snapshot.data!;
                return Transform.flip(
                  flipX: true,
                  child: IconButton(
                    icon: const Icon(Icons.reply),
                    onPressed: () {
                      // Appeler la fonction de partage avec les paramètres appropriés
                      shareEntity('user', userId, user.username);
                    },
                  ),
                );
              }
            },
          ),
          // Bouton de Suivi
          FollowingButtonWidget(entityId: userId, entityType: 'user'),
        ],
      ),
      body: FutureBuilder<User?>(
        future: UserService().getUserById(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
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
                    // Photo de Profil
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary
                                .withValues(
                                    alpha: 0.5), // Couleur de la bordure
                            width: 2.0, // Épaisseur de la bordure
                          ),
                          borderRadius: BorderRadius.circular(
                              12), // Coins arrondis de la bordure
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: ImageWithErrorHandler(
                            imageUrl: user.profilePictureUrl,
                            width: 150,
                            height: 150,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Nom d'Utilisateur
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Date d'Inscription
                    Text(
                      'Member since: ${user.createdAt.toLocal()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Compte de Followers
                    FollowersCountWidget(
                      entityId: userId,
                      entityType: 'user',
                    ),
                    const SizedBox(height: 20),
                    // Section MOOD
                    Text(
                      "MOOD",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Genre>>(
                      future: UserFollowGenreService()
                          .getFollowedGenresByUserId(userId),
                      builder: (context, genreSnapshot) {
                        if (genreSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
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
                    // Section ARTISTS
                    Text(
                      "ARTISTS",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Artist>>(
                      future: UserFollowArtistService()
                          .getFollowedArtistsByUserId(userId),
                      builder: (context, artistSnapshot) {
                        if (artistSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
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
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withValues(
                                                      alpha:
                                                          0.5), // Couleur de la bordure
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
                                              imageUrl: artist.imageUrl,
                                              width: 100,
                                              height: 100,
                                            ),
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
                    // Section VENUES
                    Text(
                      "VENUES",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Venue>>(
                      future: UserFollowVenueService()
                          .getFollowedVenuesByUserId(userId),
                      builder: (context, venueSnapshot) {
                        if (venueSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
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
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimary
                                                  .withValues(
                                                      alpha:
                                                          0.5), // Couleur de la bordure
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
                                              imageUrl: venue.imageUrl,
                                              width: 100,
                                              height: 100,
                                            ),
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
                    // Section PROMOTERS
                    Text(
                      "PROMOTERS",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Promoter>>(
                      future: UserFollowPromoterService()
                          .getFollowedPromotersByUserId(userId),
                      builder: (context, promoterSnapshot) {
                        if (promoterSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (promoterSnapshot.hasError) {
                          return Text('Error: ${promoterSnapshot.error}');
                        } else if (!promoterSnapshot.hasData ||
                            promoterSnapshot.data!.isEmpty) {
                          return const Text('No followed promoters found');
                        } else {
                          final promoters = promoterSnapshot.data!;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: promoters.map((promoter) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PromoterScreen(
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
                                                  .onPrimary
                                                  .withValues(
                                                      alpha:
                                                          0.5), // Couleur de la bordure
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
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    // Section INTERESTED EVENTS
                    Text(
                      "INTERESTED EVENTS",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getInterestedEventsByUserId(userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
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
                                subtitle: Text(formatEventDate(event.dateTime)),
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
                    // Section ATTENDED EVENTS
                    Text(
                      "ATTENDED EVENTS",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: sectionTitleSpacing),
                    FutureBuilder<List<Event>>(
                      future: UserInterestEventService()
                          .getGoingEventsByUserId(userId),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator.adaptive();
                        } else if (eventSnapshot.hasError) {
                          return Text('Error: ${eventSnapshot.error}');
                        } else if (!eventSnapshot.hasData ||
                            eventSnapshot.data!.isEmpty) {
                          return const Text('No going events found');
                        } else {
                          final events = eventSnapshot.data!;
                          return Column(
                            children: events.map((event) {
                              return ListTile(
                                title: Text(event.title),
                                subtitle: Text(formatEventDate(event.dateTime)),
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
