// search.dart

import 'package:flutter/material.dart';
import 'package:sway_events/features/artist/artist.dart';
import 'package:sway_events/features/artist/models/artist_model.dart';
import 'package:sway_events/features/artist/services/artist_service.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/event/services/event_genre_service.dart';
import 'package:sway_events/features/event/services/event_service.dart';
import 'package:sway_events/features/genre/genre.dart';
import 'package:sway_events/features/genre/models/genre_model.dart';
import 'package:sway_events/features/genre/services/genre_service.dart';
import 'package:sway_events/features/organizer/models/organizer_model.dart';
import 'package:sway_events/features/organizer/organizer.dart';
import 'package:sway_events/features/organizer/services/organizer_service.dart';
import 'package:sway_events/features/search/screens/filters_screen.dart';
import 'package:sway_events/features/user/models/user_model.dart';
import 'package:sway_events/features/user/services/user_service.dart';
import 'package:sway_events/features/user/user.dart';
import 'package:sway_events/features/venue/models/venue_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/venue/venue.dart';

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
  final OrganizerService _organizerService = OrganizerService();
  final GenreService _genreService = GenreService();
  final UserService _userService = UserService();

  Map<String, List<dynamic>> _searchResults = {};
  Map<String, dynamic> _filters = {
    'city': null,
    'date': null,
    'venueType': null,
    'genres': <String>[],
    'nearMe': false,
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
    final organizers = await _organizerService.searchOrganizers(query);
    final genres = await _genreService.searchGenres(query);
    final users = await _userService.searchUsers(query);

    setState(() {
      _searchResults = {
        'Users': users.take(5).toList(),
        'Genres': genres.take(5).toList(),
        'Artists': artists.take(5).toList(),
        'Venues': venues.take(5).toList(),
        'Organizers': organizers.take(5).toList(),
        'Events': events.take(5).toList(),
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
      setState(() {
        _filters = selectedFilters;
        _performSearch(_searchController.text);
      });
    }
  }

  void _showMapFeatureMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map feature will be integrated later.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSelectedFilters() {
    final List<Widget> filterWidgets = [];

    if (_filters['nearMe'] == true) {
      filterWidgets.add(
        Chip(
          label: const Text('Near Me'),
          onDeleted: () {
            setState(() {
              _filters['nearMe'] = false;
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
        (_filters['genres'] as List<String>)
            .map(
              (genreId) => FutureBuilder<Genre?>(
                future: _genreService.getGenreById(genreId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Chip(label: Text('Loading...'));
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return const Chip(label: Text('Error'));
                  } else {
                    final genre = snapshot.data!;
                    return Chip(
                      label: Text('Genre: ${genre.name}'),
                      onDeleted: () {
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
      child: Wrap(
        spacing: 8.0,
        children: filterWidgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText:
                'Search events, artists, venues, organizers, genres, users',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
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
        title: Text(result.username),
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
        title: Text(result.name),
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
        title: Text(result.name),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArtistScreen(artistId: result.id),
            ),
          );
        },
      );
    } else if (result is Venue) {
      return ListTile(
        title: Text(result.name),
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
              builder: (context) => VenueScreen(venueId: result.id),
            ),
          );
        },
      );
    } else if (result is Organizer) {
      return ListTile(
        title: Text(result.name),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrganizerScreen(organizerId: result.id),
            ),
          );
        },
      );
    } else if (result is Event) {
      return ListTile(
        title: Text(result.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(result.dateTime),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(result.distance),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<Genre>>(
              future: _getEventGenres(result.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      Icon(Icons.music_note, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Loading genres...'),
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
                      const Icon(Icons.music_note, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                          snapshot.data!.map((genre) => genre.name).join(', ')),
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

  Future<List<Genre>> _getEventGenres(String eventId) async {
    final genreIds = await _eventGenreService.getGenresByEventId(eventId);
    final genres =
        await Future.wait(genreIds.map((id) => _genreService.getGenreById(id)));
    return genres.whereType<Genre>().toList();
  }
}
