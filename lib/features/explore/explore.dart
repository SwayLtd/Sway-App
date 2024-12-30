// lib/features/explore/explore.dart

import 'package:flutter/material.dart';
import 'package:sway/core/constants/dimensions.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/similar_artist_service.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/notification/notification.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Services
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
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();
  final GenreService _genreService = GenreService();
  final VenueService _venueService = VenueService();

  // Futures séparés pour chaque section
  Future<List<Event>>? _suggestedEventsFuture;
  Future<List<Event>>? _upcomingEventsFuture;
  Future<List<Promoter>>? _suggestedPromotersFuture;
  Future<List<Artist>>? _suggestedArtistsFuture;
  Future<List<Venue>>? _suggestedVenuesFuture;
  Future<List<Genre>>? _suggestedGenresFuture;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      _fetchUserRecommendations(user.id);
    } else {
      // Pour les utilisateurs anonymes, fournir des recommandations génériques
      _fetchGenericRecommendations();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _fetchUserRecommendations(int userId) async {
    // Charger les événements suggérés
    _suggestedEventsFuture = _eventService.getTopEvents(limit: 5);

    // Charger les événements à venir filtrés pour l'utilisateur
    // _upcomingEventsFuture = _eventService.getEventsFilteredForUser(userId);

    // Charger les promoteurs suggérés
    _suggestedPromotersFuture = _userFollowPromoterService
        .getFollowedPromotersByUserId(userId)
        .then((followedPromoters) {
      final followedPromoterIds =
          followedPromoters.map((promoter) => promoter.id).toList();
      return _promoterService.getPromoters().then((allPromoters) => allPromoters
          .where((promoter) => !followedPromoterIds.contains(promoter.id))
          .take(3)
          .toList());
    });

    // Charger les artistes suggérés
    _suggestedArtistsFuture = _userFollowArtistService
        .getFollowedArtistsByUserId(userId)
        .then((followedArtists) async {
      final followedArtistIds =
          followedArtists.map((artist) => artist.id).toList();
      final similarArtistIds = <int>{};
      for (final artist in followedArtists) {
        final ids =
            await _similarArtistService.getSimilarArtistsByArtistId(artist.id);
        similarArtistIds.addAll(ids);
      }

      final allArtists = await _artistService.getArtists();
      final similarArtists = allArtists
          .where((a) =>
              similarArtistIds.contains(a.id) &&
              !followedArtistIds.contains(a.id))
          .toList();

      final suggestedArtists = allArtists
          .where((artist) => !followedArtistIds.contains(artist.id))
          .take(3)
          .toList();

      return [...similarArtists, ...suggestedArtists].take(3).toList();
    });

    // Charger les venues suggérées
    _suggestedVenuesFuture = _userFollowVenueService
        .getFollowedVenuesByUserId(userId)
        .then((followedVenues) {
      final followedVenueIds = followedVenues.map((venue) => venue.id).toList();
      return _venueService.getVenues().then((allVenues) => allVenues
          .where((venue) => !followedVenueIds.contains(venue.id))
          .take(3)
          .toList());
    });

    // Charger les genres suggérés
    _suggestedGenresFuture = _userFollowGenreService
        .getFollowedGenresByUserId(userId)
        .then((followedGenres) {
      final followedGenreIds = followedGenres.map((genre) => genre.id).toList();
      return _genreService.getGenres().then((allGenres) => allGenres
          .where((genre) => !followedGenreIds.contains(genre.id))
          .take(3)
          .toList());
    });
  }

  Future<void> _fetchGenericRecommendations() async {
    // Charger les événements suggérés
    _suggestedEventsFuture = _eventService.getTopEvents(limit: 5);

    // Pas de filtres spécifiques pour les événements
    _upcomingEventsFuture = Future.value([]);

    // Charger les promoteurs suggérés
    _suggestedPromotersFuture = _promoterService
        .getPromoters()
        .then((promoters) => promoters.take(3).toList());

    // Charger les artistes suggérés
    _suggestedArtistsFuture =
        _artistService.getArtists().then((artists) => artists.take(3).toList());

    // Charger les venues suggérées
    _suggestedVenuesFuture =
        _venueService.getVenues().then((venues) => venues.take(3).toList());

    // Charger les genres suggérés
    _suggestedGenresFuture =
        _genreService.getGenres().then((genres) => genres.take(6).toList());
  }

  Future<void> _refreshRecommendations() async {
    await _loadRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logotype_transparent.png',
              fit: BoxFit.contain,
              height: 28,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: <Widget>[
                const Icon(Icons.notifications),
                Positioned(
                  right: 0,
                  child: Badge(), // Badge vide comme requis
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: RefreshIndicator(
          onRefresh: _refreshRecommendations,
          child: ListView(
            children: [
              // Section "Suggested Events"
              FutureBuilder<List<Event>>(
                future: _suggestedEventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Suggested Events');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Suggested Events', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Events');
                  } else {
                    final suggestedEvents = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Events'),
                        SizedBox(height: sectionTitleSpacing),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildEventCards(
                              context,
                              suggestedEvents,
                            ),
                          ),
                        ),
                        SizedBox(height: sectionTitleSpacing),
                      ],
                    );
                  }
                },
              ),

              // Section "Upcoming Events"
              FutureBuilder<List<Event>>(
                future: _upcomingEventsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Upcoming Events');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Upcoming Events', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Upcoming Events');
                  } else {
                    final upcomingEvents = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Upcoming Events'),
                        SizedBox(height: sectionTitleSpacing),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildEventCards(
                              context,
                              upcomingEvents,
                            ),
                          ),
                        ),
                        SizedBox(height: sectionTitleSpacing),
                      ],
                    );
                  }
                },
              ),

              // Section "Suggested Promoters"
              FutureBuilder<List<Promoter>>(
                future: _suggestedPromotersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Suggested Promoters');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Suggested Promoters', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Promoters');
                  } else {
                    final suggestedPromoters = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Promoters'),
                        SizedBox(height: sectionTitleSpacing),
                        ..._buildPromoterCards(
                          context,
                          suggestedPromoters,
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),

              // Section "Suggested Artists"
              FutureBuilder<List<Artist>>(
                future: _suggestedArtistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Suggested Artists');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Suggested Artists', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Artists');
                  } else {
                    final suggestedArtists = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Artists'),
                        SizedBox(height: sectionTitleSpacing),
                        ..._buildArtistCards(
                          context,
                          suggestedArtists,
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),

              // Section "Suggested Venues"
              FutureBuilder<List<Venue>>(
                future: _suggestedVenuesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Suggested Venues');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Suggested Venues', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Venues');
                  } else {
                    final suggestedVenues = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Venues'),
                        SizedBox(height: sectionTitleSpacing),
                        ..._buildVenueCards(
                          context,
                          suggestedVenues,
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),

              // Section "Suggested Genres"
              FutureBuilder<List<Genre>>(
                future: _suggestedGenresFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingSection('Suggested Genres');
                  } else if (snapshot.hasError) {
                    return _buildErrorSection(
                        'Suggested Genres', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Genres');
                  } else {
                    final suggestedGenres = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Genres'),
                        SizedBox(height: sectionTitleSpacing),
                        _buildGenreChips(
                          context,
                          suggestedGenres,
                        ),
                        SizedBox(height: sectionSpacing),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires pour les sections

  Widget _buildLoadingSection(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /* _buildSectionTitle(title),
          SizedBox(height: sectionTitleSpacing),
          Center(child: CircularProgressIndicator()),
          SizedBox(height: sectionTitleSpacing), */
        ],
      ),
    );
  }

  Widget _buildErrorSection(String title, Object? error) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: sectionTitleSpacing),
          Center(child: Text('Erreur: $error')),
          SizedBox(height: sectionTitleSpacing),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String title) {
    return SizedBox.shrink();
    /* return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          SizedBox(height: sectionTitleSpacing),
          Center(child: Text('Aucune donnée disponible.')),
          SizedBox(height: sectionTitleSpacing),
        ],
      ),
    ); */
  }

  // Méthode pour construire les titres des sections
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Méthodes pour construire les widgets des sections
  List<Widget> _buildEventCards(BuildContext context, List<Event> events) {
    return events.map<Widget>((event) {
      return Container(
        width: 320, // Ajustez la largeur selon vos besoins
        margin: const EdgeInsets.only(right: 22, left: 4),
        child: EventCardItemWidget(
          event: event,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventScreen(event: event),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  List<Widget> _buildPromoterCards(
    BuildContext context,
    List<Promoter> promoters,
  ) {
    return promoters.map<Widget>((promoter) {
      return PromoterListItemWidget(
        promoter: promoter,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromoterScreen(promoterId: promoter.id),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildArtistCards(BuildContext context, List<Artist> artists) {
    return artists.map<Widget>((artist) {
      return ArtistListItemWidget(
        artist: artist,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(artistId: artist.id),
            ),
          );
        },
      );
    }).toList();
  }

  List<Widget> _buildVenueCards(BuildContext context, List<Venue> venues) {
    return venues.map<Widget>((venue) {
      return VenueListItemWidget(
        venue: venue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VenueScreen(venueId: venue.id),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildGenreChips(BuildContext context, List<Genre> genres) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 8.0,
        children: genres.map((genre) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GenreScreen(genreId: genre.id),
                ),
              );
            },
            child: GenreChip(genreId: genre.id),
          );
        }).toList(),
      ),
    );
  }
}

// Widget Badge (inchangé)
class Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(
        minWidth: 12,
        minHeight: 12,
      ),
      /* child: Text(
        '5',
        style: TextStyle(
          color: Theme.of(context).colorScheme.surface,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ), */
    );
  }
}
