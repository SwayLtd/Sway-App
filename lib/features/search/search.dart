// lib/features/search/search.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/features/artist/artist.dart';
import 'package:sway/features/artist/models/artist_model.dart';
import 'package:sway/features/artist/services/artist_service.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_service.dart';
import 'package:sway/features/genre/genre.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/promoter/models/promoter_model.dart';
import 'package:sway/features/promoter/promoter.dart';
import 'package:sway/features/promoter/services/promoter_service.dart';
import 'package:sway/features/search/screens/map_screen.dart';
import 'package:sway/features/search/utils/levenshtein_similarity.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/user.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';

enum SearchCategory { events, artists, genres, promoters, venues, users }

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final EventService _eventService = EventService();
  final EventGenreService _eventGenreService = EventGenreService();
  final ArtistService _artistService = ArtistService();
  final VenueService _venueService = VenueService();
  final PromoterService _promoterService = PromoterService();
  final GenreService _genreService = GenreService();
  final UserService _userService = UserService();

  // Stockage des résultats de recherche par entité
  Map<String, List<dynamic>> _searchResults = {};
  Map<String, dynamic> _filters = {
    'city': null,
    'date': null,
    'venueType': null,
    'genres': [],
    'near_me': false,
  };

  // Catégorie de recherche sélectionnée (si null, tous les résultats sont affichés)
  SearchCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = {};
      });
    } else {
      _performSearch(_searchController.text);
    }
  }

  List<Event> sortAndFilterEvents(List<Event> events, String query) {
    final now = DateTime.now();

    // Séparer événements à venir et passés
    final upcomingEvents = events
        .where((e) =>
            e.eventDateTime.isAfter(now) ||
            e.eventDateTime.isAtSameMomentAs(now))
        .toList();

    final pastEvents =
        events.where((e) => e.eventDateTime.isBefore(now)).toList();

    // Filtrer les événements passés qui correspondent bien à la recherche
    final matchingPastEvents = pastEvents.where((event) {
      double matchScore = similarity(event.title, query);
      return matchScore >= 0.8; // Seuil ajustable en fonction de vos besoins
    }).toList();

    // Tri des événements à venir (les plus proches en premier)
    upcomingEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
    // Tri des événements passés par ordre décroissant (les plus récents d'abord)
    matchingPastEvents
        .sort((a, b) => b.eventDateTime.compareTo(a.eventDateTime));

    // Combiner les résultats : afficher d'abord les événements à venir puis les événements passés correspondants
    return [...upcomingEvents, ...matchingPastEvents];
  }

  List<Event> sortUpcomingEvents(List<Event> events) {
    final now = DateTime.now();
    // Keep only future events (including events starting exactly now)
    final futureEvents = events
        .where((e) =>
            e.eventDateTime.isAfter(now) ||
            e.eventDateTime.isAtSameMomentAs(now))
        .toList();
    // Sort events in ascending order: soonest event first.
    futureEvents.sort((a, b) => a.eventDateTime.compareTo(b.eventDateTime));
    return futureEvents;
  }

// Example integration in _performSearch:
  Future<void> _performSearch(String query) async {
    final events = await _eventService.searchEvents(query, _filters);
    // Utilisation de la nouvelle fonction de tri et filtrage
    // final events = sortAndFilterEvents(eventsRaw, query);
    // final events = sortUpcomingEvents(eventsRaw);
    final artists = await _artistService.searchArtists(query);
    final venues = await _venueService.searchVenues(query);
    final promoters = await _promoterService.searchPromoters(query);
    final genres = await _genreService.searchGenres(query);
    final users = await _userService.searchUsers(query);

    if (!mounted) return;
    setState(() {
      _searchResults = {
        'Events': events.take(10).toList(),
        'Artists': artists.take(10).toList(),
        'Promoters': promoters.take(10).toList(),
        'Venues': venues.take(10).toList(),
        'Genres': genres.take(10).toList(),
        'Users': users.take(10).toList(),
      };

      _searchResults.removeWhere((key, value) => value.isEmpty);

      _searchResults = Map.fromEntries(
        _searchResults.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length)),
      );
    });
  }

  // Ligne horizontale des tuiles de catégories
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        children: SearchCategory.values.map((category) {
          String label;
          switch (category) {
            case SearchCategory.events:
              label = 'Events';
              break;
            case SearchCategory.artists:
              label = 'Artists';
              break;
            case SearchCategory.genres:
              label = 'Genres';
              break;
            case SearchCategory.promoters:
              label = 'Promoters';
              break;
            case SearchCategory.venues:
              label = 'Venues';
              break;
            case SearchCategory.users:
              label = 'Users';
              break;
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(label),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                setState(() {
                  // Si on clique sur le même chip, on désélectionne pour afficher tous
                  _selectedCategory =
                      (selected && _selectedCategory != category)
                          ? category
                          : null;
                  _performSearch(_searchController.text);
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedFilters() {
    final List<Widget> filterWidgets = [];

    if (_filters['near_me'] == true) {
      filterWidgets.add(
        Chip(
          label: const Text('Near Me'),
          onDeleted: () {
            if (!mounted) return;
            setState(() {
              _filters['near_me'] = false;
              _performSearch(_searchController.text);
            });
          },
        ),
      );
    }
    if (_filters['cities'] != null && (_filters['cities'] as List).isNotEmpty) {
      filterWidgets.addAll(
        (_filters['cities'] as List<String>)
            .map(
              (city) => Chip(
                label: Text('City: $city'),
                onDeleted: () {
                  if (!mounted) return;
                  setState(() {
                    (_filters['cities'] as List).remove(city);
                    _performSearch(_searchController.text);
                  });
                },
              ),
            )
            .toList(),
      );
    }
    if (_filters['date'] != null) {
      filterWidgets.add(
        Chip(
          label: Text(
            'Date: ${_filters['date'].toString().split(' ')[0]}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onDeleted: () {
            if (!mounted) return;
            setState(() {
              _filters['date'] = null;
              _performSearch(_searchController.text);
            });
          },
        ),
      );
    }
    if (_filters['venueTypes'] != null &&
        (_filters['venueTypes'] as List).isNotEmpty) {
      filterWidgets.addAll(
        (_filters['venueTypes'] as List<String>)
            .map(
              (type) => Chip(
                label: Text(
                  'Venue Type: $type',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onDeleted: () {
                  if (!mounted) return;
                  setState(() {
                    (_filters['venueTypes'] as List).remove(type);
                    _performSearch(_searchController.text);
                  });
                },
              ),
            )
            .toList(),
      );
    }
    if (_filters['genres'] != null && (_filters['genres'] as List).isNotEmpty) {
      filterWidgets.addAll(
        (_filters['genres'] as List)
            .map(
              (genreId) => FutureBuilder<Genre?>(
                future: _genreService.getGenreById(genreId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Chip(label: Text('Loading'));
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const Chip(label: Text('Error'));
                  } else {
                    final genre = snapshot.data!;
                    return Chip(
                      label: Text('Genre: ${genre.name}'),
                      onDeleted: () {
                        if (!mounted) return;
                        setState(() {
                          (_filters['genres'] as List).remove(genreId);
                          _performSearch(_searchController.text);
                        });
                      },
                    );
                  }
                },
              ),
            )
            .toList(),
      );
    }

    if (filterWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 8.0,
          children: filterWidgets,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildListTile(dynamic result) {
    if (result is User) {
      return ListTile(
        title: Text(
          result.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserScreen(userId: result.id),
            ),
          );
        },
      );
    } else if (result is Genre) {
      return ListTile(
        title: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenreScreen(genreId: result.id),
            ),
          );
        },
      );
    } else if (result is Artist) {
      return ListTile(
        title: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(artistId: result.id!),
            ),
          );
        },
      );
    } else if (result is Venue) {
      return ListTile(
        title: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                result.location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VenueScreen(venueId: result.id!),
            ),
          );
        },
      );
    } else if (result is Promoter) {
      return ListTile(
        title: Text(
          result.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromoterScreen(promoterId: result.id!),
            ),
          );
        },
      );
    } else if (result is Event) {
      return ListTile(
        title: Text(
          result.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                // Formater la date de l'événement en utilisant date_utils.dart
                Text(
                  formatEventDate(result.eventDateTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Text(
                  formatEventTime(result.eventDateTime),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<Genre>>(
              future: _getEventGenres(result.id!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Icon(Icons.music_note, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Loading genres'),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return const Row(
                    children: [
                      Icon(Icons.error, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Error loading genres'),
                    ],
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Row(
                    children: [
                      Icon(Icons.music_note, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('No genres available'),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      const Icon(Icons.music_note,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          snapshot.data!.map((genre) => genre.name).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventScreen(event: result),
            ),
          );
        },
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Future<List<Genre>> _getEventGenres(int eventId) async {
    final genreIds = await _eventGenreService.getGenresByEventId(eventId);
    final genres =
        await Future.wait(genreIds.map((id) => _genreService.getGenreById(id)));
    return genres.whereType<Genre>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                'Search events, artists, venues, promoters, genres, users',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                if (!mounted) return;
                setState(() {
                  _searchResults = {};
                });
              },
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () async {
              Position? currentPosition;
              try {
                // Check if location services are enabled
                bool serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();
                if (!serviceEnabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Location services are disabled. Please enable them."),
                    ),
                  );
                } else {
                  // Check the current permission
                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  // If permission is denied or deniedForever, request permission again
                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    permission = await Geolocator.requestPermission();
                  }
                  // If permission is granted, get the current position
                  if (permission == LocationPermission.always ||
                      permission == LocationPermission.whileInUse) {
                    currentPosition = await Geolocator.getCurrentPosition(
                      locationSettings: const LocationSettings(
                        accuracy: LocationAccuracy.best,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Location permission is denied."),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              } catch (e) {
                debugPrint("Error getting current location: $e");
              }

              // Use currentPosition if available, otherwise fallback to default coordinates
              LatLng center = currentPosition != null
                  ? LatLng(currentPosition.latitude, currentPosition.longitude)
                  : const LatLng(50.8477, 4.3572);

              // Navigate to MapScreen with the determined center
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => MapScreen(initialCenter: center),
                ),
              );
            },
          ),
          // Bouton de filtre temporairement désactivé
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Feature in development'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Tuiles de sélection de catégorie
          _buildCategoryChips(),
          const SizedBox(height: 8),
          _buildSelectedFilters(),
          Expanded(
            child: ListView(
              children: _searchResults.entries.expand<Widget>((entry) {
                // Si une catégorie est sélectionnée, ne garder que la section correspondante.
                if (_selectedCategory != null) {
                  String selectedKey =
                      _selectedCategory.toString().split('.').last;
                  if (entry.key.toLowerCase() != selectedKey.toLowerCase()) {
                    return [];
                  }
                }
                return [
                  _buildSectionTitle(entry.key),
                  ...entry.value
                      .map<Widget>((result) => _buildListTile(result)),
                ];
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
