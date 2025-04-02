import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/artist/widgets/artist_item_shimmer.dart';
import 'package:sway/features/artist/widgets/artist_item_widget.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/event/widgets/event_item_shimmer.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/explore/widgets/random_greeting_tile.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/genre/widgets/genre_chip.dart';
import 'package:sway/features/genre/widgets/genre_item_shimmer.dart';
import 'package:sway/features/notification/notification.dart';
import 'package:sway/features/notification/services/notification_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/promoter/widgets/promoter_item_shimmer.dart';
import 'package:sway/features/search/screens/map_screen.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/widgets/snackbar_login.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';
import 'package:sway/features/promoter/widgets/promoter_item_widget.dart';
import 'package:sway/features/venue/widgets/venue_item_shimmer.dart';
import 'package:sway/features/venue/widgets/venue_item_widget.dart';
import 'package:sway/features/event/widgets/event_info_tile.dart';

// Import des modal bottom sheets existants
import 'package:sway/features/artist/widgets/artist_modal_bottom_sheet.dart';
import 'package:sway/features/promoter/widgets/promoter_modal_bottom_sheet.dart';
import 'package:sway/features/venue/widgets/venue_modal_bottom_sheet.dart';
import 'package:sway/features/genre/widgets/genre_modal_bottom_sheet.dart';
import 'package:sway/features/event/widgets/event_modal_bottom_sheet.dart';

class ExploreScreen extends StatefulWidget {
  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // Services
  final UserService _userService = UserService();
  final EventService _eventService = EventService();
  final PromoterService _promoterService = PromoterService();
  final ArtistService _artistService = ArtistService();
  final GenreService _genreService = GenreService();
  final VenueService _venueService = VenueService();

  // Futures pour chaque section
  Future<List<Event>>? _topEventsFuture;
  Future<List<Event>>? _suggestedEventsFuture;
  Future<List<Artist>>? _suggestedArtistsFuture;
  Future<List<Promoter>>? _suggestedPromotersFuture;
  Future<List<Venue>>? _suggestedVenuesFuture;
  Future<List<Genre>>? _suggestedGenresFuture;

  // Stockage pour les données affichées dans les modals
  List<Event> _allTopEvents = [];
  List<Event> _allSuggestedEvents = [];
  List<Artist> _allSuggestedArtists = [];
  List<Promoter> _allSuggestedPromoters = [];
  List<Venue> _allSuggestedVenues = [];
  List<Genre> _allSuggestedGenres = [];

  // Key pour le rafraîchissement de la section EventInfoTile
  Key _eventInfoRefreshKey = UniqueKey();

  bool _isLoggedIn = false;
  // Current user stored to pass username to RandomGreetingTile.
  var _currentUser;

  // Indicateur pour savoir si toutes les futures sont terminées
  bool _allLoaded = false;
  // Indicateur pour savoir si au moins une section a renvoyé des données
  bool _hasContent = false;

  final ScrollController _scrollController = ScrollController();
  bool _showMapButton = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    // Display permissions dialog after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      // If the permission has not yet been authorized, the dialog is displayed.
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        NotificationService().showPermissionRequestDialog(context);
      }
    });

    // Détection du scroll pour afficher le bouton Map dès qu'on scrolle vers le bas
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_showMapButton) {
        setState(() {
          _showMapButton = true;
        });
      } else if (_scrollController.offset <= 100 && _showMapButton) {
        setState(() {
          _showMapButton = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Charge les recommandations et l'utilisateur courant.
  Future<void> _loadRecommendations() async {
    // Réinitialiser _hasContent à chaque chargement
    setState(() {
      _hasContent = false;
    });

    _currentUser = await _userService.getCurrentUser();
    if (_currentUser != null) {
      _isLoggedIn = true;
      await _fetchUserRecommendations(_currentUser.id);
    } else {
      _isLoggedIn = false;
      await _fetchGenericRecommendations();
    }
    // Marquer le chargement global comme terminé.
    setState(() {
      _allLoaded = true;
    });
  }

  /// Pour utilisateur connecté.
  Future<void> _fetchUserRecommendations(int userId) async {
    _topEventsFuture = _eventService.getTopEvents(userId: userId, limit: 10);
    _suggestedEventsFuture =
        _eventService.getRecommendedEvents(userId: userId, limit: 10);
    _suggestedArtistsFuture =
        _artistService.getRecommendedArtists(userId: userId, limit: 10);
    _suggestedPromotersFuture =
        _promoterService.getRecommendedPromoters(userId: userId, limit: 10);
    _suggestedVenuesFuture =
        _venueService.getRecommendedVenues(userId: userId, limit: 10);
    _suggestedGenresFuture =
        _genreService.getRecommendedGenres(userId: userId, limit: 10);

    try {
      await Future.wait([
        _topEventsFuture!,
        _suggestedEventsFuture!,
        _suggestedArtistsFuture!,
        _suggestedPromotersFuture!,
        _suggestedVenuesFuture!,
        _suggestedGenresFuture!,
      ]);
    } catch (e) {
      // En cas d'erreur, on continue pour permettre l'affichage
    }
  }

  /// Pour utilisateur anonyme.
  Future<void> _fetchGenericRecommendations() async {
    _topEventsFuture = _eventService.getTopEvents(userId: null, limit: 10);
    _suggestedEventsFuture =
        _eventService.getRecommendedEvents(userId: null, limit: 10);
    _suggestedArtistsFuture =
        _artistService.getRecommendedArtists(userId: null, limit: 10);
    _suggestedPromotersFuture =
        _promoterService.getRecommendedPromoters(userId: null, limit: 10);
    _suggestedVenuesFuture =
        _venueService.getRecommendedVenues(userId: null, limit: 10);
    _suggestedGenresFuture =
        _genreService.getRecommendedGenres(userId: null, limit: 10);

    try {
      await Future.wait([
        _topEventsFuture!,
        _suggestedEventsFuture!,
        _suggestedArtistsFuture!,
        _suggestedPromotersFuture!,
        _suggestedVenuesFuture!,
        _suggestedGenresFuture!,
      ]);
    } catch (e) {
      // En cas d'erreur, on continue pour permettre l'affichage
    }
  }

  Future<void> _refreshRecommendations() async {
    setState(() {
      _eventInfoRefreshKey = UniqueKey();
      _allLoaded = false;
      _hasContent = false;
    });
    await _loadRecommendations();
  }

  /// Construction du shimmer selon la section.
  Widget _buildLoadingSection(String title) {
    switch (title) {
      case 'Top Events':
      case 'Suggested Events':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  2,
                  (_) => Container(
                    width: 310.0,
                    height: 242.0,
                    margin: const EdgeInsets.only(right: 22, left: 4),
                    child: const EventCardShimmer(
                        itemCount: 1, itemWidth: 310.0, itemHeight: 242.0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24.0),
          ],
        );
      case 'Suggested Artists':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title, false),
            const SizedBox(height: 16.0),
            ...List.generate(3, (_) => const ArtistShimmer()),
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
                children: List.generate(3, (_) => const PromoterShimmer()),
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
            ...List.generate(3, (_) => const VenueShimmer()),
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

  /// Construit le titre de la section avec éventuellement l'icône "Voir plus".
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
                switch (title.toUpperCase()) {
                  case 'TOP EVENTS':
                    _showMoreEvents(_allTopEvents);
                    break;
                  case 'SUGGESTED EVENTS':
                    _showMoreEvents(_allSuggestedEvents);
                    break;
                  case 'SUGGESTED ARTISTS':
                    _showMoreArtists(_allSuggestedArtists);
                    break;
                  case 'SUGGESTED PROMOTERS':
                    _showMorePromoters(_allSuggestedPromoters);
                    break;
                  case 'SUGGESTED VENUES':
                    _showMoreVenues(_allSuggestedVenues);
                    break;
                  case 'SUGGESTED GENRES':
                    _showMoreGenres(_allSuggestedGenres);
                    break;
                }
              },
            ),
        ],
      ),
    );
  }

  /// Fonctions d'affichage des modals "Voir plus".
  void _showMoreEvents(List<Event> events) {
    final limited = events.take(12).toList();
    showEventModalBottomSheet(context, limited);
  }

  void _showMoreArtists(List<Artist> artists) {
    final limited = artists.take(12).toList();
    showArtistModalBottomSheet(context, limited);
  }

  void _showMorePromoters(List<Promoter> promoters) {
    final limited = promoters.take(12).toList();
    showPromoterModalBottomSheet(context, limited);
  }

  void _showMoreVenues(List<Venue> venues) {
    final limited = venues.take(12).toList();
    showVenueModalBottomSheet(context, limited);
  }

  void _showMoreGenres(List<Genre> genres) {
    final limited = genres.map((genre) => genre.id).take(12).toList();
    showGenreModalBottomSheet(context, limited);
  }

  /// Construction des widgets pour chaque section.
  List<Widget> _buildEventCards(BuildContext context, List<Event> events) {
    return events.map<Widget>((event) {
      return Container(
        width: 320,
        margin: const EdgeInsets.only(right: 22, left: 4),
        child: EventCardItemWidget(
          event: event,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => EventScreen(event: event)),
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
                builder: (context) => ArtistScreen(artistId: artist.id!)),
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
                builder: (context) => PromoterScreen(promoterId: promoter.id!)),
          );
        },
        maxNameLength: 20,
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
                builder: (context) => VenueScreen(venueId: venue.id!)),
          );
        },
        maxNameLength: 20,
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
                    builder: (context) => GenreScreen(genreId: genre.id)),
              );
            },
            child: GenreChip(genreId: genre.id),
          );
        }).toList(),
      ),
    );
  }

  // Méthode pour obtenir la localisation actuelle et ouvrir MapScreen
  Future<void> _openMapScreen() async {
    Position? currentPosition;
    try {
      // Vérifier que les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                "Les services de localisation sont désactivés. Merci de les activer."),
          ),
        );
      } else {
        // Vérifier la permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
        }
        // Si la permission est accordée, récupérer la position
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("La permission de localisation est refusée."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération de la localisation : $e");
    }

    // Définir le centre avec la position actuelle si disponible, sinon une valeur par défaut
    LatLng center = currentPosition != null
        ? LatLng(currentPosition.latitude, currentPosition.longitude)
        : const LatLng(50.8477, 4.3572);

    // Naviguer vers MapScreen avec le centre déterminé
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => MapScreen(initialCenter: center),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si le chargement global est terminé et qu'aucune section n'a fourni de données (_hasContent == false),
    // on souhaite afficher les shimmers (les loadingSection).
    bool showFallback = _allLoaded && !_hasContent;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
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
                      : Colors.grey,
                ),
                Positioned(
                  right: 0,
                  child: Badge(),
                ),
              ],
            ),
            onPressed: () {
              if (_isLoggedIn) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationScreen()));
              } else {
                SnackbarLogin.showLoginSnackBar(context);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshRecommendations,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Section principale
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Column(
                      children: [
                        RandomGreetingTile(username: _currentUser?.username),
                        if (_isLoggedIn)
                          EventInfoTile(refreshKey: _eventInfoRefreshKey),
                        // Section Top Events
                        FutureBuilder<List<Event>>(
                          future: _topEventsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection('Top Events');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection('Top Events');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allTopEvents = snapshot.data!;
                              final displayCount = 5;
                              final hasMore =
                                  _allTopEvents.length > displayCount;
                              final displayEvents = hasMore
                                  ? _allTopEvents.sublist(0, displayCount)
                                  : _allTopEvents;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Top Events', hasMore),
                                  const SizedBox(height: 16.0),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: _buildEventCards(
                                            context, displayEvents)),
                                  ),
                                  const SizedBox(height: 24.0),
                                ],
                              );
                            }
                          },
                        ),
                        // Section Suggested Events
                        FutureBuilder<List<Event>>(
                          future: _suggestedEventsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection('Suggested Events');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection('Suggested Events');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allSuggestedEvents = snapshot.data!;
                              final displayCount = 5;
                              final hasMore =
                                  _allSuggestedEvents.length > displayCount;
                              final displayEvents = hasMore
                                  ? _allSuggestedEvents.sublist(0, displayCount)
                                  : _allSuggestedEvents;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Suggested Events', hasMore),
                                  const SizedBox(height: 16.0),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                        children: _buildEventCards(
                                            context, displayEvents)),
                                  ),
                                  const SizedBox(height: 24.0),
                                ],
                              );
                            }
                          },
                        ),
                        // Section Suggested Artists
                        FutureBuilder<List<Artist>>(
                          future: _suggestedArtistsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection('Suggested Artists');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection('Suggested Artists');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allSuggestedArtists = snapshot.data!;
                              final displayCount = 3;
                              final hasMore =
                                  _allSuggestedArtists.length > displayCount;
                              final displayArtists = hasMore
                                  ? _allSuggestedArtists.sublist(
                                      0, displayCount)
                                  : _allSuggestedArtists;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Suggested Artists', hasMore),
                                  const SizedBox(height: 16.0),
                                  ..._buildArtistCards(context, displayArtists),
                                  const SizedBox(height: 24.0),
                                ],
                              );
                            }
                          },
                        ),
                        // Section Suggested Promoters
                        FutureBuilder<List<Promoter>>(
                          future: _suggestedPromotersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection(
                                  'Suggested Promoters');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection(
                                  'Suggested Promoters');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allSuggestedPromoters = snapshot.data!;
                              final displayCount = 3;
                              final hasMore =
                                  _allSuggestedPromoters.length > displayCount;
                              final displayPromoters = hasMore
                                  ? _allSuggestedPromoters.sublist(
                                      0, displayCount)
                                  : _allSuggestedPromoters;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Suggested Promoters', hasMore),
                                  const SizedBox(height: 16.0),
                                  ..._buildPromoterCards(
                                      context, displayPromoters),
                                  const SizedBox(height: 24.0),
                                ],
                              );
                            }
                          },
                        ),
                        // Section Suggested Venues
                        FutureBuilder<List<Venue>>(
                          future: _suggestedVenuesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection('Suggested Venues');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection('Suggested Venues');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allSuggestedVenues = snapshot.data!;
                              final displayCount = 3;
                              final hasMore =
                                  _allSuggestedVenues.length > displayCount;
                              final displayVenues = hasMore
                                  ? _allSuggestedVenues.sublist(0, displayCount)
                                  : _allSuggestedVenues;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Suggested Venues', hasMore),
                                  const SizedBox(height: 16.0),
                                  ..._buildVenueCards(context, displayVenues),
                                  const SizedBox(height: 24.0),
                                ],
                              );
                            }
                          },
                        ),
                        // Section Suggested Genres
                        FutureBuilder<List<Genre>>(
                          future: _suggestedGenresFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildLoadingSection('Suggested Genres');
                            } else if (snapshot.hasError) {
                              return _buildLoadingSection('Suggested Genres');
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              if (!_hasContent) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  if (!_hasContent) {
                                    setState(() {
                                      _hasContent = true;
                                    });
                                  }
                                });
                              }
                              _allSuggestedGenres = snapshot.data!;
                              final displayCount = 6;
                              final hasMore =
                                  _allSuggestedGenres.length > displayCount;
                              final displayGenres = hasMore
                                  ? _allSuggestedGenres.sublist(0, displayCount)
                                  : _allSuggestedGenres;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle(
                                      'Suggested Genres', hasMore),
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
                // Affichage global des loadingSection en fallback uniquement
                // si le chargement global est terminé (_allLoaded == true)
                // et qu'aucune section n'a fourni de données (_hasContent == false)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: showFallback
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLoadingSection('Top Events'),
                              _buildLoadingSection('Suggested Events'),
                              _buildLoadingSection('Suggested Artists'),
                              _buildLoadingSection('Suggested Promoters'),
                              _buildLoadingSection('Suggested Venues'),
                              _buildLoadingSection('Suggested Genres'),
                            ],
                          ),
                        )
                      : Container(),
                ),
              ],
            ),
          ),
          // Bouton "Map" positionné par-dessus
          if (_showMapButton)
            Positioned(
              bottom: 16,
              left: (MediaQuery.of(context).size.width - 100) /
                  2, // Centre horizontalement le bouton
              child: SizedBox(
                width: 100, // Largeur réduite
                height: 40, // Hauteur plus petite
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20), // Bords arrondis
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8), // Ajustement du padding interne
                  ),
                  onPressed: _openMapScreen,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.map, size: 18),
                      SizedBox(width: 4),
                      Text(
                        "Map",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Widget Badge pour notifications.
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
    );
  }
}
