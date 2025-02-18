// search.dart

import 'package:flutter/material.dart';
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
import 'package:sway/features/search/screens/filters_screen.dart';
import 'package:sway/features/user/models/user_model.dart';
import 'package:sway/features/user/services/user_service.dart';
import 'package:sway/features/user/user.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/features/venue/services/venue_service.dart';
import 'package:sway/features/venue/venue.dart';

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

  Map<String, List<dynamic>> _searchResults = {};
  Map<String, dynamic> _filters = {
    'city': null,
    'date': null,
    'venueType': null,
    'genres': [],
    'near_me': false,
  };

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

  Future<void> _performSearch(String query) async {
    final events = await _eventService.searchEvents(query, _filters);
    final artists = await _artistService.searchArtists(query);
    final venues = await _venueService.searchVenues(query);
    final promoters = await _promoterService.searchPromoters(query);
    final genres = await _genreService.searchGenres(query);
    final users = await _userService.searchUsers(query);

    if (!mounted) return;
    setState(() {
      _searchResults = {
        'Events': events.take(5).toList(),
        'Promoters': promoters.take(5).toList(),
        'Artists': artists.take(5).toList(),
        'Venues': venues.take(5).toList(),
        'Genres': genres.take(5).toList(),
        'Users': users.take(5).toList(),
      };

      _searchResults.removeWhere((key, value) => value.isEmpty);

      _searchResults = Map.fromEntries(
        _searchResults.entries.toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length)),
      );
    });
  }

  Future<void> _showFilters() async {
    final Map<String, dynamic>? selectedFilters = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FiltersScreen(filters: _filters),
      ),
    );

    if (selectedFilters != null) {
      if (!mounted) return;
      setState(() {
        _filters = selectedFilters;
        _performSearch(_searchController.text);
      });
    }
  }

  void _showMapFeatureMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Map feature will be integrated later.'),
        duration: Duration(seconds: 2),
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
          label: Text('Date: ${_filters['date'].toString().split(' ')[0]}'),
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
                label: Text('Venue Type: $type'),
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
            icon: const Icon(Icons.map),
            onPressed: _showMapFeatureMessage,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSelectedFilters(),
          ..._searchResults.entries.expand((entry) {
            return [
              _buildSectionTitle(entry.key),
              ...entry.value.map((result) => _buildListTile(result)),
            ];
          }),
        ],
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
            Text(result.location),
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
                Text(result.eventDateTime.toString()),
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
                      const Icon(
                        Icons.music_note,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        snapshot.data!.map((genre) => genre.name).join(', '),
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
}
