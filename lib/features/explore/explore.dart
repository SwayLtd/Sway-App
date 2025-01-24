// lib/features/explore/explore.dart

import 'package:flutter/material.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/services/similar_artist_service.dart';
import 'package:sway/features/artist/widgets/artist_item_shimmer.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/widgets/event_item_shimmer.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_item_shimmer.dart';
import 'package:sway/features/notification/notification.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/promoter/widgets/promoter_item_shimmer.dart';
import 'package:sway/features/user/services/user_follow_artist_service.dart';
import 'package:sway/features/user/services/user_follow_genre_service.dart';
import 'package:sway/features/user/services/user_follow_promoter_service.dart';
import 'package:sway/features/user/services/user_follow_venue_service.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_item_shimmer.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';

// Import des modal bottom sheets existants
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/venue/widgets/venue_modal_bottom_sheet.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart'; // Import de EventModalBottomSheet

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
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();
  final GenreService _genreService = GenreService();
  final VenueService _venueService = VenueService();

  // Futures séparés pour chaque section
  Future<List<Event>>? _suggestedEventsFuture;
  Future<List<Promoter>>? _suggestedPromotersFuture;
  Future<List<Artist>>? _suggestedArtistsFuture;
  Future<List<Venue>>? _suggestedVenuesFuture;
  Future<List<Genre>>? _suggestedGenresFuture;

  // Variables pour stocker toutes les suggestions afin de les passer aux modals
  List<Event> _allSuggestedEvents = [];
  List<Promoter> _allSuggestedPromoters = [];
  List<Artist> _allSuggestedArtists = [];
  List<Venue> _allSuggestedVenues = [];
  List<Genre> _allSuggestedGenres = [];

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  /// Charge les recommandations en fonction de l'utilisateur connecté
  Future<void> _loadRecommendations() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      _isLoggedIn = true; // L'utilisateur est connecté
      await _fetchUserRecommendations(user.id);
    } else {
      _isLoggedIn = false; // L'utilisateur n'est pas connecté
      await _fetchGenericRecommendations();
    }
    if (!mounted) return;
    setState(() {}); // Mettre à jour l'UI
  }

  /// Charge les recommandations spécifiques à l'utilisateur
  Future<void> _fetchUserRecommendations(int userId) async {
    // Charger les événements suggérés
    _suggestedEventsFuture =
        _eventService.getTopEvents(limit: 10); // Fetch more for modal

    // Charger les promoteurs suggérés
    _suggestedPromotersFuture = _userFollowPromoterService
        .getFollowedPromotersByUserId(userId)
        .then((followedPromoters) async {
      final followedPromoterIds =
          followedPromoters.map((promoter) => promoter.id!).toList();
      final allPromoters = await _promoterService.getPromoters();
      return allPromoters
          .where((promoter) => !followedPromoterIds.contains(promoter.id!))
          .toList();
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
          .toList();

      return [...similarArtists, ...suggestedArtists];
    });

    // Charger les venues suggérées
    _suggestedVenuesFuture = _userFollowVenueService
        .getFollowedVenuesByUserId(userId)
        .then((followedVenues) async {
      final followedVenueIds =
          followedVenues.map((venue) => venue.id!).toList();
      final allVenues = await _venueService.getVenues();
      return allVenues
          .where((venue) => !followedVenueIds.contains(venue.id!))
          .toList();
    });

    // Charger les genres suggérés
    _suggestedGenresFuture = _userFollowGenreService
        .getFollowedGenresByUserId(userId)
        .then((followedGenres) async {
      final followedGenreIds = followedGenres.map((genre) => genre.id).toList();
      final allGenres = await _genreService.getGenres();
      return allGenres
          .where((genre) => !followedGenreIds.contains(genre.id))
          .toList();
    });
  }

  /// Charge des recommandations génériques pour les utilisateurs anonymes
  Future<void> _fetchGenericRecommendations() async {
    // Charger les événements suggérés
    _suggestedEventsFuture =
        _eventService.getTopEvents(limit: 10); // Fetch more for modal

    // Charger les promoteurs suggérés
    _suggestedPromotersFuture =
        _promoterService.getPromoters().then((promoters) => promoters);

    // Charger les artistes suggérés
    _suggestedArtistsFuture =
        _artistService.getArtists().then((artists) => artists);

    // Charger les venues suggérées
    _suggestedVenuesFuture = _venueService.getVenues().then((venues) => venues);

    // Charger les genres suggérés
    _suggestedGenresFuture = _genreService.getGenres().then((genres) => genres);
  }

  /// Rafraîchit les recommandations
  Future<void> _refreshRecommendations() async {
    await _loadRecommendations();
  }

  /// Méthode pour construire les sections de chargement avec Shimmer
  Widget _buildLoadingSection(String title) {
    switch (title) {
      case 'Suggested Events':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            _buildSectionTitle(title, false),
            const SizedBox(height: 28.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: EventCardShimmer(
                itemCount: 2, // Nombre de shimmer items
                itemWidth: 310.0,
                itemHeight: 242.0,
              ),
            ),
            const SizedBox(height: 41.0),
          ],
        );
      case 'Suggested Artists':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            ...List.generate(3, (index) => const ArtistShimmer()),
            const SizedBox(height: 24.0),
          ],
        );
      case 'Suggested Promoters':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: Column(
                children: [
                  ...List.generate(3, (index) => const PromoterShimmer())
                ],
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        );
      case 'Suggested Venues':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            ...List.generate(3, (index) => const VenueShimmer()),
            const SizedBox(height: 24.0),
          ],
        );
      case 'Suggested Genres':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            const GenreShimmer(),
            const SizedBox(height: 24.0),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Méthode pour construire les sections en cas d'erreur
  /* Widget _buildErrorSection(String title, Object? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title, false),
        const SizedBox(height: 16.0),
        Center(child: Text('Error: $error')),
        const SizedBox(height: 16.0),
      ],
    );
  } */

  /// Méthode pour construire les sections vides
  Widget _buildEmptySection(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /* _buildSectionTitle(title, false),
          const SizedBox(height: 16.0),
          const Center(child: Text('Aucune donnée disponible.')),
          const SizedBox(height: 16.0), */
      ],
    );
  }

  /// Méthode pour construire les titres des sections avec icône "Voir plus" si nécessaire
  Widget _buildSectionTitle(String title, bool hasMore) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment:
            hasMore ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (hasMore)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                switch (title) {
                  case 'Suggested Artists':
                    _showMoreArtists(_allSuggestedArtists);
                    break;
                  case 'Suggested Promoters':
                    _showMorePromoters(_allSuggestedPromoters);
                    break;
                  case 'Suggested Venues':
                    _showMoreVenues(_allSuggestedVenues);
                    break;
                  case 'Suggested Genres':
                    _showMoreGenres(_allSuggestedGenres);
                    break;
                  case 'Suggested Events':
                    _showMoreEvents(_allSuggestedEvents);
                    break;
                  default:
                    break;
                }
              },
            ),
        ],
      ),
    );
  }

  /// Méthodes pour construire les widgets des sections
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

  List<Widget> _buildPromoterCards(
      BuildContext context, List<Promoter> promoters) {
    return promoters.map<Widget>((promoter) {
      return PromoterListItemWidget(
        promoter: promoter,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromoterScreen(promoterId: promoter.id!),
            ),
          );
        },
        maxNameLength: 20, // Définissez la longueur maximale ici
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
              builder: (context) => VenueScreen(venueId: venue.id!),
            ),
          );
        },
        maxNameLength: 20, // Définissez la longueur maximale ici
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

  // Fonctions pour ouvrir les modal bottom sheets avec limitation
  void _showMoreArtists(List<Artist> artists) {
    final limitedArtists = artists.take(12).toList();
    showArtistModalBottomSheet(context, limitedArtists);
  }

  void _showMorePromoters(List<Promoter> promoters) {
    final limitedPromoters = promoters.take(12).toList();
    showPromoterModalBottomSheet(context, limitedPromoters);
  }

  void _showMoreVenues(List<Venue> venues) {
    final limitedVenues = venues.take(12).toList();
    showVenueModalBottomSheet(context, limitedVenues);
  }

  void _showMoreGenres(List<Genre> genres) {
    final limitedGenres = genres.map((genre) => genre.id).take(12).toList();
    showGenreModalBottomSheet(context, limitedGenres);
  }

  void _showMoreEvents(List<Event> events) {
    final limitedEvents = events.take(12).toList();
    showEventModalBottomSheet(context, limitedEvents);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
                Icon(
                  Icons.notifications,
                  color: _isLoggedIn
                      ? Theme.of(context).iconTheme.color
                      : Colors.grey, // Couleur conditionnelle
                ),
                Positioned(
                  right: 0,
                  child: Badge(), // Badge vide comme requis
                ),
              ],
            ),
            onPressed: () {
              if (_isLoggedIn) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationScreen()),
                );
              } else {
                SnackbarLogin.showLoginSnackBar(context);
              }
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
                    return _buildLoadingSection('Suggested Events');
                    // return _buildErrorSection('Suggested Events', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Events');
                  } else {
                    final suggestedEvents = snapshot.data!;
                    _allSuggestedEvents =
                        suggestedEvents; // Stockage pour modal (si nécessaire)
                    final displayCount =
                        5; // Nombre d'événements à afficher initialement
                    final hasMore = suggestedEvents.length > displayCount;
                    final displayEvents = hasMore
                        ? suggestedEvents.sublist(0, displayCount)
                        : suggestedEvents;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8.0),
                        _buildSectionTitle('Suggested Events', hasMore),
                        const SizedBox(height: 16.0),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _buildEventCards(context, displayEvents),
                          ),
                        ),
                        const SizedBox(height: 24.0),
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
                    return _buildLoadingSection('Suggested Artists');
                    // return _buildErrorSection('Suggested Artists', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Artists');
                  } else {
                    final suggestedArtists = snapshot.data!;
                    _allSuggestedArtists =
                        suggestedArtists; // Stockage pour modal
                    final displayCount =
                        3; // Nombre d'artistes à afficher initialement
                    final hasMore = suggestedArtists.length > displayCount;
                    final displayArtists = hasMore
                        ? suggestedArtists.sublist(0, displayCount)
                        : suggestedArtists;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Artists', hasMore),
                        const SizedBox(height: 16.0),
                        ..._buildArtistCards(context, displayArtists),
                        const SizedBox(height: 24.0),
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
                    return _buildLoadingSection('Suggested Promoters');
                    // return _buildErrorSection('Suggested Promoters', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Promoters');
                  } else {
                    final suggestedPromoters = snapshot.data!;
                    _allSuggestedPromoters =
                        suggestedPromoters; // Stockage pour modal
                    final displayCount =
                        3; // Nombre de promoteurs à afficher initialement
                    final hasMore = suggestedPromoters.length > displayCount;
                    final displayPromoters = hasMore
                        ? suggestedPromoters.sublist(0, displayCount)
                        : suggestedPromoters;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Promoters', hasMore),
                        const SizedBox(height: 16.0),
                        ..._buildPromoterCards(context, displayPromoters),
                        const SizedBox(height: 24.0),
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
                    return _buildLoadingSection('Suggested Venues');
                    // return _buildErrorSection('Suggested Venues', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Venues');
                  } else {
                    final suggestedVenues = snapshot.data!;
                    _allSuggestedVenues =
                        suggestedVenues; // Stockage pour modal
                    final displayCount =
                        3; // Nombre de lieux à afficher initialement
                    final hasMore = suggestedVenues.length > displayCount;
                    final displayVenues = hasMore
                        ? suggestedVenues.sublist(0, displayCount)
                        : suggestedVenues;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Venues', hasMore),
                        const SizedBox(height: 16.0),
                        ..._buildVenueCards(context, displayVenues),
                        const SizedBox(height: 24.0),
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
                    return _buildLoadingSection('Suggested Genres');
                    // return _buildErrorSection('Suggested Genres', snapshot.error);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptySection('Suggested Genres');
                  } else {
                    final suggestedGenres = snapshot.data!;
                    _allSuggestedGenres =
                        suggestedGenres; // Stockage pour modal
                    final displayCount =
                        6; // Nombre de genres à afficher initialement
                    final hasMore = suggestedGenres.length > displayCount;
                    final displayGenres = hasMore
                        ? suggestedGenres.sublist(0, displayCount)
                        : suggestedGenres;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Suggested Genres', hasMore),
                        const SizedBox(height: 16.0),
                        _buildGenreChips(context, displayGenres),
                        const SizedBox(height: 24.0),
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
}

/// Widget Badge
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
