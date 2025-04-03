// search_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // for date formatting

// --- Global Supabase instance ---
final supabaseClient = Supabase.instance.client;

// --- Enum for search entity types ---
enum EntityType { all, event, artist, venue, promoter, genre, user }

// --- Class to hold the search filters state ---
// On ajoute selectedCity, cityLat et cityLon pour gérer le filtre de ville
class SearchFilters {
  EntityType entityType;
  DateTime? date;
  List<int> genreIds;
  // On remplace le booléen nearMe par une sélection de ville (incluant "Near Me")
  final String? selectedCity;
  final double? cityLat;
  final double? cityLon;
  bool onlyFollowed;
  bool friendsInterested;
  String? eventType; // For events
  String? venueType; // For venues

  SearchFilters({
    this.entityType = EntityType.all,
    this.date,
    this.genreIds = const [],
    this.selectedCity,
    this.cityLat,
    this.cityLon,
    this.onlyFollowed = false,
    this.friendsInterested = false,
    this.eventType,
    this.venueType,
  });
}

// --- Main search screen widget ---
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchFilters _filters = SearchFilters();
  List<dynamic> _results = [];

  // Simulated user position for Brussels
  final double currentUserLat = 50.8503;
  final double currentUserLon = 4.3517;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final params = <String, dynamic>{};

    // En mode global, si aucune entité n'est sélectionnée, le RPC renvoie union events/venues.
    EntityType effectiveEntity = _filters.entityType;
    if (effectiveEntity == EntityType.all) {
      if (_filters.date != null || _filters.eventType != null) {
        effectiveEntity = EntityType.event;
      }
    }
    if (effectiveEntity != EntityType.all) {
      params['p_entity_type'] = _entityTypeParam(effectiveEntity);
    }
    if (_filters.date != null) {
      params['p_date'] = _filters.date!.toIso8601String();
    }
    if (_filters.genreIds.isNotEmpty) {
      params['p_genre_ids'] = _filters.genreIds;
    }
    // Si un filtre de ville est sélectionné, on utilise soit "Near Me" (coordonnées actuelles)
    // soit les coordonnées de la ville choisie.
    if (_filters.selectedCity != null) {
      if (_filters.selectedCity == "Near Me") {
        params['p_lat'] = currentUserLat;
        params['p_lon'] = currentUserLon;
      } else {
        params['p_lat'] = _filters.cityLat;
        params['p_lon'] = _filters.cityLon;
      }
      params['p_radius_km'] = 50;
    }
    if (_filters.onlyFollowed) {
      params['p_only_followed'] = true;
    }
    if (_filters.friendsInterested) {
      params['p_friends_interested'] = true;
    }
    if (query.isNotEmpty) {
      params['p_query'] = query;
    }
    params['p_user_id'] = 123; // Remplacer par l'ID réel de l'utilisateur

    try {
      final response =
          await supabaseClient.rpc('search_entities', params: params);
      setState(() {
        _results = response as List<dynamic>;
      });
    } catch (error) {
      debugPrint("Error during search: $error");
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'event':
        return Icons.event;
      case 'artist':
        return Icons.music_note;
      case 'venue':
        return Icons.location_on;
      case 'promoter':
        return Icons.campaign;
      case 'genre':
        return Icons.category;
      case 'user':
        return Icons.person;
      default:
        return Icons.search;
    }
  }

  String _entityTypeParam(EntityType type) {
    switch (type) {
      case EntityType.event:
        return 'events';
      case EntityType.artist:
        return 'artists';
      case EntityType.venue:
        return 'venues';
      case EntityType.promoter:
        return 'promoters';
      case EntityType.genre:
        return 'genres';
      case EntityType.user:
        return 'users';
      case EntityType.all:
        return '';
    }
  }

  String _entityTypeLabel(EntityType type) {
    switch (type) {
      case EntityType.event:
        return 'Events';
      case EntityType.artist:
        return 'Artists';
      case EntityType.venue:
        return 'Venues';
      case EntityType.promoter:
        return 'Promoters';
      case EntityType.genre:
        return 'Genres';
      case EntityType.user:
        return 'Users';
      case EntityType.all:
        return 'All';
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Widget _buildActiveFilterChips() {
    List<Widget> chips = [];
    if (_filters.entityType != EntityType.all) {
      chips.add(Chip(
        label: Text(_entityTypeLabel(_filters.entityType)),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(); // réinitialise tous les filtres
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.date != null) {
      chips.add(Chip(
        label: Text("Date: ${_formatDate(_filters.date!)}"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              genreIds: _filters.genreIds,
              onlyFollowed: _filters.onlyFollowed,
              friendsInterested: _filters.friendsInterested,
              eventType: _filters.eventType,
              venueType: _filters.venueType,
            );
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.selectedCity != null) {
      chips.add(Chip(
        label: Text("Ville: ${_filters.selectedCity}"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              date: _filters.date,
              genreIds: _filters.genreIds,
              onlyFollowed: _filters.onlyFollowed,
              friendsInterested: _filters.friendsInterested,
              eventType: _filters.eventType,
              venueType: _filters.venueType,
            );
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.onlyFollowed) {
      chips.add(Chip(
        label: Text("Followed Events"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              date: _filters.date,
              genreIds: _filters.genreIds,
              selectedCity: _filters.selectedCity,
              cityLat: _filters.cityLat,
              cityLon: _filters.cityLon,
              friendsInterested: _filters.friendsInterested,
              eventType: _filters.eventType,
              venueType: _filters.venueType,
            );
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.friendsInterested) {
      chips.add(Chip(
        label: Text("Friends Interested"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              date: _filters.date,
              genreIds: _filters.genreIds,
              selectedCity: _filters.selectedCity,
              cityLat: _filters.cityLat,
              cityLon: _filters.cityLon,
              onlyFollowed: _filters.onlyFollowed,
              eventType: _filters.eventType,
              venueType: _filters.venueType,
            );
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    for (int genreId in _filters.genreIds) {
      chips.add(Chip(
        label: Text(genreId.toString()),
        onDeleted: () {
          setState(() {
            _filters.genreIds.remove(genreId);
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    return chips.isEmpty
        ? SizedBox.shrink()
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: chips),
          );
  }

  Widget _buildResultsList() {
    if (_results.isEmpty) {
      return Center(child: Text("No results"));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        String type = item['type'];
        String name = item['name'];
        String? description = item['description'];
        return ListTile(
          leading: Icon(_iconForType(type)),
          title: Text(name),
          subtitle: description != null && description.isNotEmpty
              ? Text(description)
              : null,
          onTap: () {
            // Navigation vers les détails
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search (events, artists, venues, etc.)',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                });
              },
            ),
          ),
          onSubmitted: (query) => _performSearch(query),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            tooltip: "Advanced Filters",
            onPressed: () async {
              final newFilters = await showModalBottomSheet<SearchFilters>(
                context: context,
                isScrollControlled: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) =>
                    FilterModalSheet(initialFilters: _filters),
              );
              if (newFilters != null) {
                setState(() {
                  _filters = newFilters;
                });
                _performSearch(_searchController.text);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 8),
          _buildActiveFilterChips(),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }
}

// --- Bottom Sheet for advanced filters ---
class FilterModalSheet extends StatefulWidget {
  final SearchFilters initialFilters;
  const FilterModalSheet({Key? key, required this.initialFilters})
      : super(key: key);
  @override
  _FilterModalSheetState createState() => _FilterModalSheetState();
}

class _FilterModalSheetState extends State<FilterModalSheet> {
  // Pour la sélection d'entité (null = global mode)
  EntityType? _selectedEntity;
  DateTime? _selectedDate;
  late List<int> _selectedGenreIds;
  // Variable pour stocker les genres populaires récupérés via RPC
  List<Map<String, dynamic>> _popularGenres = [];
  // Remplacement de nearMe par la sélection de ville (via FilterChip)
  Map<String, dynamic>? _selectedCityOption;
  bool _onlyFollowed = false;
  bool _friendsInterested = false;
  String? _selectedEventType;
  String? _selectedVenueType;

  @override
  void initState() {
    super.initState();
    _selectedEntity = widget.initialFilters.entityType == EntityType.all
        ? null
        : widget.initialFilters.entityType;
    _selectedDate = widget.initialFilters.date;
    _selectedGenreIds = List<int>.from(widget.initialFilters.genreIds);
    _onlyFollowed = widget.initialFilters.onlyFollowed;
    _friendsInterested = widget.initialFilters.friendsInterested;
    _selectedEventType = widget.initialFilters.eventType;
    _selectedVenueType = widget.initialFilters.venueType;
    if (widget.initialFilters.selectedCity != null) {
      _selectedCityOption = {
        'name': widget.initialFilters.selectedCity,
        'lat': widget.initialFilters.cityLat,
        'lon': widget.initialFilters.cityLon,
      };
    }
    _loadPopularGenres();
  }

  Future<void> _loadPopularGenres() async {
    final response = await supabaseClient.rpc('get_popular_genres');
    if (response != null) {
      setState(() {
        _popularGenres = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  // Build FilterChips pour les genres populaires
  List<Widget> _buildGenreChips() {
    if (_popularGenres.isEmpty) {
      return [CircularProgressIndicator()];
    }
    return _popularGenres.map((genre) {
      int genreId = genre['id'];
      return FilterChip(
        label: Text(genre['name']),
        selected: _selectedGenreIds.contains(genreId),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedGenreIds.add(genreId);
            } else {
              _selectedGenreIds.remove(genreId);
            }
          });
        },
      );
    }).toList();
  }

  // Build FilterChips pour la sélection d'entité
  Widget _buildEntityTypeChips() {
    final Map<EntityType, String> entityChoices = {
      EntityType.event: 'Events',
      EntityType.artist: 'Artists',
      EntityType.venue: 'Venues',
      EntityType.promoter: 'Promoters',
      EntityType.genre: 'Genres',
      EntityType.user: 'Users',
    };
    return Wrap(
      spacing: 8.0,
      children: entityChoices.entries.map((entry) {
        return FilterChip(
          label: Text(entry.value),
          selected: _selectedEntity == entry.key,
          onSelected: (selected) {
            setState(() {
              if (_selectedEntity == entry.key) {
                _selectedEntity = null;
              } else {
                _selectedEntity = entry.key;
              }
              _selectedDate = null;
              _selectedGenreIds.clear();
              _selectedCityOption = null;
              _onlyFollowed = false;
              _friendsInterested = false;
              _selectedEventType = null;
              _selectedVenueType = null;
            });
          },
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Build FilterChips pour la sélection de ville / Near Me
  List<Widget> _buildCityChips() {
    final List<Map<String, dynamic>> cityOptions = [
      {'name': 'Near Me'},
      {'name': 'Bruxelles', 'lat': 50.8503, 'lon': 4.3517},
      {'name': 'Paris', 'lat': 48.8566, 'lon': 2.3522},
      {'name': 'Amsterdam', 'lat': 52.3676, 'lon': 4.9041},
      {'name': 'Berlin', 'lat': 52.5200, 'lon': 13.4050},
      {'name': 'Milan', 'lat': 45.4642, 'lon': 9.1900},
      {'name': 'Barcelone', 'lat': 41.3851, 'lon': 2.1734},
      {'name': 'Madrid', 'lat': 40.4168, 'lon': -3.7038},
    ];
    return cityOptions.map((city) {
      bool selected = _selectedCityOption != null &&
          _selectedCityOption!['name'] == city['name'];
      return FilterChip(
        label: Text(city['name']),
        selected: selected,
        onSelected: (_) {
          setState(() {
            if (selected) {
              _selectedCityOption = null;
            } else {
              _selectedCityOption = city;
            }
          });
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(EdgeInsets.all(16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Search Filters',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                )
              ],
            ),
            SizedBox(height: 8),
            Text("Select Entity Type",
                style: TextStyle(fontWeight: FontWeight.bold)),
            _buildEntityTypeChips(),
            Divider(),
            // Affichage dynamique des filtres selon l'entité sélectionnée
            if (_selectedEntity == null) ...[
              // Filtres globaux
              Text("Global Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6.0,
                children: [
                  FilterChip(
                    label: Text(_selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : "Select Date"),
                    selected: _selectedDate != null,
                    onSelected: (_) async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(Duration(days: 365)),
                        lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                      );
                      setState(() {
                        _selectedDate = picked;
                      });
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 6.0,
                children: _buildCityChips(),
              ),
              Wrap(
                spacing: 6.0,
                children: [
                  FilterChip(
                    label: Text("Followed Events"),
                    selected: _onlyFollowed,
                    onSelected: (selected) {
                      setState(() {
                        _onlyFollowed = selected;
                      });
                    },
                  ),
                  FilterChip(
                    label: Text("Friends Interested"),
                    selected: _friendsInterested,
                    onSelected: (selected) {
                      setState(() {
                        _friendsInterested = selected;
                      });
                    },
                  ),
                ],
              ),
              // Affichage des genres populaires récupérés via RPC
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
            ] else if (_selectedEntity == EntityType.event) ...[
              Text("Event Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ListTile(
                title: Text(_selectedDate != null
                    ? "Date: ${_formatDate(_selectedDate!)}"
                    : "Select a date"),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(Duration(days: 365)),
                    lastDate: DateTime.now().add(Duration(days: 365 * 2)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
              DropdownButton<String>(
                hint: Text("Event Type"),
                value: _selectedEventType,
                items: _getEventTypes()
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEventType = val;
                  });
                },
              ),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              CheckboxListTile(
                title: Text("Only interested/going"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: Text("Friends interested"),
                value: _friendsInterested,
                onChanged: (val) {
                  setState(() {
                    _friendsInterested = val ?? false;
                  });
                },
              ),
            ] else if (_selectedEntity == EntityType.venue) ...[
              Text("Venue Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                hint: Text("Venue Type"),
                value: _selectedVenueType,
                items: _getVenueTypes()
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedVenueType = val;
                  });
                },
              ),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              CheckboxListTile(
                title: Text("Only followed venues"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ] else if (_selectedEntity == EntityType.artist) ...[
              Text("Artist Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              CheckboxListTile(
                title: Text("Only followed artists"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ] else if (_selectedEntity == EntityType.promoter) ...[
              Text("Promoter Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              CheckboxListTile(
                title: Text("Only followed promoters"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ] else if (_selectedEntity == EntityType.genre) ...[
              Text("Genre Filters",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: Text("Only followed genres"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ] else if (_selectedEntity == EntityType.user) ...[
              Text("No additional filters for Users",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
            SizedBox(height: 16),
            Wrap(
              children: [
                TextButton(
                  child: Text("Clear filters"),
                  onPressed: () {
                    setState(() {
                      _selectedEntity = null;
                      _selectedDate = null;
                      _selectedGenreIds.clear();
                      _selectedCityOption = null;
                      _onlyFollowed = false;
                      _friendsInterested = false;
                      _selectedEventType = null;
                      _selectedVenueType = null;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              child: Text("Apply"),
              onPressed: () {
                EntityType effectiveEntity = _selectedEntity ?? EntityType.all;
                if (effectiveEntity == EntityType.all) {
                  if (_selectedDate != null || _selectedEventType != null) {
                    effectiveEntity = EntityType.event;
                  }
                }
                SearchFilters newFilters = SearchFilters(
                  entityType: effectiveEntity,
                  date: _selectedDate,
                  genreIds: _selectedGenreIds,
                  onlyFollowed: _onlyFollowed,
                  friendsInterested: _friendsInterested,
                  eventType: effectiveEntity == EntityType.event
                      ? _selectedEventType
                      : null,
                  venueType: effectiveEntity == EntityType.venue
                      ? _selectedVenueType
                      : null,
                  selectedCity: _selectedCityOption != null
                      ? _selectedCityOption!['name']
                      : null,
                  cityLat: _selectedCityOption != null &&
                          _selectedCityOption!.containsKey('lat')
                      ? _selectedCityOption!['lat']
                      : null,
                  cityLon: _selectedCityOption != null &&
                          _selectedCityOption!.containsKey('lon')
                      ? _selectedCityOption!['lon']
                      : null,
                );
                Navigator.pop(context, newFilters);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Fonctions statiques pour les types d'événements et de venues (inchangées)
  List<String> _getEventTypes() {
    return ['Concert', 'Party', 'Conference'];
  }

  List<String> _getVenueTypes() {
    return ['Club', 'Bar', 'Theatre'];
  }
}
