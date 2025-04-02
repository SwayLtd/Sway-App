// search_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // for date formatting

// --- Global Supabase instance ---
final supabaseClient = Supabase.instance.client;

// --- Enum for search entity types ---
enum EntityType { all, event, artist, venue, promoter, genre, user }

// --- Class to hold the search filters state ---
class SearchFilters {
  EntityType entityType;
  DateTime? date;
  List<int> genreIds;
  bool nearMe;
  String? city;
  bool onlyFollowed;
  bool friendsInterested;

  SearchFilters({
    this.entityType = EntityType.all,
    this.date,
    this.genreIds = const [],
    this.nearMe = false,
    this.city,
    this.onlyFollowed = false,
    this.friendsInterested = false,
  });
}

// --- Main search screen widget ---
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Controller for the search text field
  final TextEditingController _searchController = TextEditingController();
  // Current search filters
  SearchFilters _filters = SearchFilters();
  // List of search results returned by the RPC
  List<dynamic> _results = [];

  // Simulated user position for Brussels instead of Paris
  final double currentUserLat = 50.8503; // Brussels latitude
  final double currentUserLon = 4.3517; // Brussels longitude

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Call RPC to perform search with the current filters
  Future<void> _performSearch(String query) async {
    final params = <String, dynamic>{};

    if (_filters.entityType != EntityType.all) {
      params['p_entity_type'] = _entityTypeParam(_filters.entityType);
    }
    if (_filters.date != null) {
      params['p_date'] = _filters.date!.toIso8601String();
    }
    if (_filters.genreIds.isNotEmpty) {
      params['p_genre_ids'] = _filters.genreIds;
    }
    if (_filters.nearMe) {
      params['p_lat'] = currentUserLat;
      params['p_lon'] = currentUserLon;
      params['p_radius_km'] = 50; // Example: 50km radius for "near me"
    }
    if (_filters.city != null) {
      params['p_city'] = _filters.city;
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
    // The current user's internal ID (an integer) is retrieved via UserService
    params['p_user_id'] =
        123; // Replace with the actual user ID from UserService

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

  // Returns an icon based on the entity type (to be adapted)
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

  // Returns the RPC parameter value corresponding to an EntityType
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

  // Returns the display label for an EntityType
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

  // Format a date as dd/MM/yyyy
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Example function to get a genre name from its ID (adapt as needed)
  String _genreNameFromId(int id) {
    final genreMap = {
      1: "Rock",
      2: "Pop",
      3: "Jazz",
      4: "Electro",
      5: "Hip-Hop",
    };
    return genreMap[id] ?? "Genre $id";
  }

  // Example function returning all available genres
  List<Map<String, dynamic>> _getAllGenres() {
    return [
      {'id': 1, 'name': 'Rock'},
      {'id': 2, 'name': 'Pop'},
      {'id': 3, 'name': 'Jazz'},
      {'id': 4, 'name': 'Electro'},
      {'id': 5, 'name': 'Hip-Hop'},
    ];
  }

  // Build chips to display active filters
  Widget _buildActiveFilterChips() {
    List<Widget> chips = [];
    if (_filters.entityType != EntityType.all) {
      chips.add(Chip(
        label: Text(_entityTypeLabel(_filters.entityType)),
        onDeleted: () {
          setState(() {
            _filters.entityType = EntityType.all;
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
            _filters.date = null;
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    for (int genreId in _filters.genreIds) {
      chips.add(Chip(
        label: Text(_genreNameFromId(genreId)),
        onDeleted: () {
          setState(() {
            _filters.genreIds.remove(genreId);
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.city != null) {
      chips.add(Chip(
        label: Text(_filters.city!),
        onDeleted: () {
          setState(() {
            _filters.city = null;
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.nearMe) {
      chips.add(Chip(
        label: Text("Near Me"),
        onDeleted: () {
          setState(() {
            _filters.nearMe = false;
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.onlyFollowed) {
      chips.add(Chip(
        label: Text("Followed"),
        onDeleted: () {
          setState(() {
            _filters.onlyFollowed = false;
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
            _filters.friendsInterested = false;
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

  // Build the list of search results
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
            // Implement navigation to the entity details screen
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
  late EntityType _selectedEntity;
  DateTime? _selectedDate;
  late List<int> _selectedGenreIds;
  bool _nearMe = false;
  String? _selectedCity;
  bool _onlyFollowed = false;
  bool _friendsInterested = false;

  @override
  void initState() {
    super.initState();
    _selectedEntity = widget.initialFilters.entityType;
    _selectedDate = widget.initialFilters.date;
    _selectedGenreIds = List<int>.from(widget.initialFilters.genreIds);
    _nearMe = widget.initialFilters.nearMe;
    _selectedCity = widget.initialFilters.city;
    _onlyFollowed = widget.initialFilters.onlyFollowed;
    _friendsInterested = widget.initialFilters.friendsInterested;
  }

  // Example static list of available genres
  List<Map<String, dynamic>> _getAllGenres() {
    return [
      {'id': 1, 'name': 'Rock'},
      {'id': 2, 'name': 'Pop'},
      {'id': 3, 'name': 'Jazz'},
      {'id': 4, 'name': 'Electro'},
      {'id': 5, 'name': 'Hip-Hop'},
    ];
  }

  // Build FilterChips for genre selection
  List<Widget> _buildGenreChips() {
    return _getAllGenres().map((genre) {
      return FilterChip(
        label: Text(genre['name']),
        selected: _selectedGenreIds.contains(genre['id']),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedGenreIds.add(genre['id']);
            } else {
              _selectedGenreIds.remove(genre['id']);
            }
          });
        },
      );
    }).toList();
  }

  // Format a date for display
  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Save the current filters preset (example implementation)
  void _saveFiltersPreset() {
    // Implement saving (e.g., using SharedPreferences)
    debugPrint(
        "Filters saved: $_selectedEntity, date: $_selectedDate, genres: $_selectedGenreIds");
  }

  @override
  Widget build(BuildContext context) {
    // List of available entity choices for filtering
    final entityChoices = {
      EntityType.all: 'All',
      EntityType.event: 'Events',
      EntityType.artist: 'Artists',
      EntityType.venue: 'Venues',
      EntityType.promoter: 'Promoters',
      EntityType.genre: 'Genres',
      EntityType.user: 'Users',
    };

    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(EdgeInsets.all(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal header row
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
            // Entity type selection using ChoiceChips
            Wrap(
              spacing: 8.0,
              children: entityChoices.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: _selectedEntity == entry.key,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedEntity = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            Divider(),
            // Dynamic filters based on the selected entity
            if (_selectedEntity == EntityType.event ||
                _selectedEntity == EntityType.all) ...[
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
              SwitchListTile(
                title: Text("Near Me"),
                value: _nearMe,
                onChanged: (val) {
                  setState(() {
                    _nearMe = val;
                    if (val) _selectedCity = null;
                  });
                },
              ),
              DropdownButton<String>(
                hint: Text("Major City"),
                value: _selectedCity,
                items: <String>[
                  'Brussels',
                  'Paris',
                  'London',
                  'Berlin',
                  'Madrid'
                ]
                    .map((city) =>
                        DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCity = val;
                    if (val != null) _nearMe = false;
                  });
                },
              ),
              SizedBox(height: 8),
              Text("Genres:", style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              CheckboxListTile(
                title: Text("Only followed events"),
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
            ],
            if (_selectedEntity == EntityType.artist) ...[
              SizedBox(height: 8),
              Text("Artist Genres:",
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
            ],
            if (_selectedEntity == EntityType.venue) ...[
              SizedBox(height: 8),
              Text("Venue event genres:",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6.0,
                children: _buildGenreChips(),
              ),
              SwitchListTile(
                title: Text("Near Me"),
                value: _nearMe,
                onChanged: (val) {
                  setState(() {
                    _nearMe = val;
                    if (val) _selectedCity = null;
                  });
                },
              ),
              DropdownButton<String>(
                hint: Text("Major City"),
                value: _selectedCity,
                items: <String>['Brussels', 'Paris', 'London', 'Berlin']
                    .map((city) =>
                        DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCity = val;
                    if (val != null) _nearMe = false;
                  });
                },
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
            ],
            if (_selectedEntity == EntityType.promoter) ...[
              SizedBox(height: 8),
              Text("Preferred genres:",
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
            ],
            if (_selectedEntity == EntityType.genre) ...[
              CheckboxListTile(
                title: Text("Only followed genres"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ],
            if (_selectedEntity == EntityType.user) ...[
              CheckboxListTile(
                title: Text("Only followed users"),
                value: _onlyFollowed,
                onChanged: (val) {
                  setState(() {
                    _onlyFollowed = val ?? false;
                  });
                },
              ),
            ],
            SizedBox(height: 16),
            // Action buttons
            Wrap(
              children: [
                TextButton(
                  child: Text("Clear filters"),
                  onPressed: () {
                    setState(() {
                      _selectedEntity = EntityType.all;
                      _selectedDate = null;
                      _selectedGenreIds.clear();
                      _nearMe = false;
                      _selectedCity = null;
                      _onlyFollowed = false;
                      _friendsInterested = false;
                    });
                  },
                ),
                TextButton(
                  child: Text("Save my filters"),
                  onPressed: () {
                    _saveFiltersPreset();
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Filters saved")));
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              child: Text("Apply"),
              onPressed: () {
                SearchFilters newFilters = SearchFilters(
                  entityType: _selectedEntity,
                  date: _selectedDate,
                  genreIds: _selectedGenreIds,
                  nearMe: _selectedCity == null ? _nearMe : false,
                  city: _selectedCity,
                  onlyFollowed: _onlyFollowed,
                  friendsInterested: _friendsInterested,
                );
                Navigator.pop(context, newFilters);
              },
            ),
          ],
        ),
      ),
    );
  }
}
