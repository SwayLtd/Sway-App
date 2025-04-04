// search_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/search/screens/map_screen.dart';
import 'package:sway/features/user/services/user_service.dart'; // Pour récupérer l'utilisateur courant

// --- Global Supabase instance ---
final supabaseClient = Supabase.instance.client;

// --- Enum for search entity types ---
enum EntityType { all, event, artist, venue, promoter, genre, user }

// --- Class to hold the search filters state ---
class SearchFilters {
  EntityType entityType;
  DateTime? date;
  List<int> genreIds;
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
  bool _isLoading = false; // Pour gérer l'état de chargement

  // Variables pour la géolocalisation de l'utilisateur
  double? _currentUserLat;
  double? _currentUserLon;

  // Map pour stocker l'association ID -> nom du genre
  Map<int, String> _genreMap = {};

  @override
  void initState() {
    super.initState();
    _loadGenres();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    Position? currentPosition;
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text("Location services are disabled. Please enable them."),
          ),
        );
      } else {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          permission = await Geolocator.requestPermission();
        }
        // If permission is granted, retrieve the current position
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
      debugPrint("Error while retrieving location: $e");
    }
    setState(() {
      _currentUserLat = currentPosition?.latitude ?? 50.8503;
      _currentUserLon = currentPosition?.longitude ?? 4.3517;
    });
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await GenreService().getGenres();
      setState(() {
        _genreMap = {for (var genre in genres) genre.id: genre.name};
      });
    } catch (e) {
      debugPrint("Error loading genres: $e");
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });
    final params = <String, dynamic>{};

    // If the entity is not "all", add the p_entity_type parameter
    if (_filters.entityType != EntityType.all) {
      params['p_entity_type'] = _entityTypeParam(_filters.entityType);
      // For a specific entity filter (like venues), ignore area parameters:
      if (_filters.entityType != EntityType.all) {
        // Option 1: Clear area parameters to force the specific branch
        // (Assuming you want venues without filtering by area)
      }
    }
    if (_filters.date != null) {
      params['p_date'] = _filters.date!.toIso8601String();
    }
    if (_filters.genreIds.isNotEmpty) {
      params['p_genre_ids'] = _filters.genreIds;
    }
    // Only add area parameters if no specific entity is selected (i.e. global mode)
    if (_filters.entityType == EntityType.all &&
        _filters.selectedCity != null) {
      if (_filters.selectedCity == "Near Me") {
        params['p_lat'] = _currentUserLat ?? 50.8503;
        params['p_lon'] = _currentUserLon ?? 4.3517;
      } else {
        params['p_lat'] = _filters.cityLat;
        params['p_lon'] = _filters.cityLon;
      }
      params['p_radius_km'] = 50;
    }
    if (query.isNotEmpty) {
      params['p_query'] = query;
    }
    // Retrieve the current user ID via UserService.
    final user = await UserService().getCurrentUser();
    params['p_user_id'] = user?.id;

    try {
      final response =
          await supabaseClient.rpc('search_entities', params: params);
      setState(() {
        _results = response as List<dynamic>;
      });
    } catch (error) {
      debugPrint("Error during search: $error");
    }
    setState(() {
      _isLoading = false;
    });
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
        return Icons.queue_music; // Updated icon for genres
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

  // Affiche les chips actives pour les filtres
  Widget _buildActiveFilterChips() {
    List<Widget> chips = [];
    if (_filters.entityType != EntityType.all) {
      chips.add(Chip(
        label: Text(_entityTypeLabel(_filters.entityType)),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters();
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    if (_filters.date != null) {
      chips.add(Chip(
        label: Text("${_formatDate(_filters.date!)}"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              genreIds: _filters.genreIds,
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
        label: Text("${_filters.selectedCity}"),
        onDeleted: () {
          setState(() {
            _filters = SearchFilters(
              entityType: _filters.entityType,
              date: _filters.date,
              genreIds: _filters.genreIds,
              eventType: _filters.eventType,
              venueType: _filters.venueType,
            );
          });
          _performSearch(_searchController.text);
        },
      ));
    }
    for (int genreId in _filters.genreIds) {
      chips.add(
        FutureBuilder<Genre?>(
          future: GenreService().getGenreById(genreId),
          builder: (context, snapshot) {
            String label;
            if (snapshot.connectionState == ConnectionState.waiting) {
              label = 'Loading';
            } else if (snapshot.hasError || snapshot.data == null) {
              label = 'Error';
            } else {
              label = snapshot.data!.name;
            }
            return Chip(
              label: Text(label),
              onDeleted: () {
                setState(() {
                  _filters.genreIds.remove(genreId);
                });
                _performSearch(_searchController.text);
              },
            );
          },
        ),
      );
    }
    return chips.isEmpty
        ? SizedBox.shrink()
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width,
              ),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: chips
                      .map((chip) => Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: chip,
                          ))
                      .toList(),
                ),
              ),
            ),
          );
  }

  // Liste des résultats cliquables via GoRouter et affichant un indicateur de chargement
  Widget _buildResultsList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    if (_results.isEmpty) {
      return Container(); // Affiche rien si aucun résultat (sans "No results")
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
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: description != null && description.isNotEmpty
              ? Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () {
            // Navigation via GoRouter selon le type
            switch (type) {
              case 'artist':
                context.push('/artist/${item['id']}');
                break;
              case 'promoter':
                context.push('/promoter/${item['id']}');
                break;
              case 'venue':
                context.push('/venue/${item['id']}');
                break;
              case 'genre':
                context.push('/genre/${item['id']}');
                break;
              case 'user':
                context.push('/user/${item['id']}');
                break;
              case 'event':
              default:
                context.push('/event/${item['id']}');
                break;
            }
          },
        );
      },
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
            content:
                Text("Location services are disabled. Please activate them."),
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
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permission to locate is refused."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error retrieving location: $e");
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
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText:
                'Search events, artists, genres, promoters, venues and users',
            border: InputBorder.none,
            // Suffix icons: search icon and (optionally) clear button
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search),
                // You can uncomment the following to add a clear button:
                // IconButton(
                //   icon: Icon(Icons.clear),
                //   onPressed: () {
                //     _searchController.clear();
                //     setState(() {
                //       _results = [];
                //     });
                //   },
                // ),
              ],
            ),
          ),
          onSubmitted: (query) => _performSearch(query),
        ),
        actions: [
          // Map button placed before the filters button:
          IconButton(
            icon: Icon(Icons.map_outlined),
            tooltip: "Map",
            onPressed: () => _openMapScreen(),
          ),
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
  // Utilisation du dropdown pour la sélection d'entité
  late EntityType _selectedEntity;
  DateTime? _selectedDate;
  late List<int> _selectedGenreIds;
  List<Map<String, dynamic>> _popularGenres = [];
  Map<String, dynamic>? _selectedCityOption;
  String? _selectedEventType;
  String? _selectedVenueType;

  @override
  void initState() {
    super.initState();
    _selectedEntity = widget.initialFilters.entityType;
    _selectedDate = widget.initialFilters.date;
    _selectedGenreIds = List<int>.from(widget.initialFilters.genreIds);
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

  // Widget de titre de section
  Widget _buildSectionTitle(String title, {VoidCallback? onMore}) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 8.0, right: 8.0, top: 12.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: onMore != null
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (onMore != null)
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: onMore,
            ),
        ],
      ),
    );
  }

  // Sélection d'entité via dropdown
  Widget _buildEntitySelection() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 220),
            child: Text(
              "What are you looking for?",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<EntityType>(
              value: _selectedEntity,
              isExpanded: true,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedEntity = value;
                    _selectedDate = null;
                    _selectedGenreIds.clear();
                    // If user selects venues, clear the area filters to avoid sending area parameters.
                    if (value == EntityType.venue) {
                      _selectedCityOption = null;
                    }
                    _selectedEventType = null;
                    _selectedVenueType = null;
                  });
                }
              },
              items: EntityType.values.map((entity) {
                return DropdownMenuItem(
                  value: entity,
                  child: Text(_entityTypeLabel(entity)),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
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

  // Date field sous forme de TextField classique
  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: "DATE",
          hintText: _selectedDate != null
              ? _formatDate(_selectedDate!)
              : "Select Date",
          suffixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        onTap: () async {
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
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
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

  // Build FilterChips pour la sélection de ville / AREA
  List<Widget> _buildCityChips() {
    final List<Map<String, dynamic>> cityOptions = [
      {'name': 'Near Me'},
      {'name': 'Brussels', 'lat': 50.8503, 'lon': 4.3517},
      {'name': 'Paris', 'lat': 48.8566, 'lon': 2.3522},
      {'name': 'Amsterdam', 'lat': 52.3676, 'lon': 4.9041},
      {'name': 'Berlin', 'lat': 52.5200, 'lon': 13.4050},
      {'name': 'Milan', 'lat': 45.4642, 'lon': 9.1900},
      {'name': 'Barcelona', 'lat': 41.3851, 'lon': 2.1734},
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
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre grise en haut
            Center(
              child: Container(
                height: 5,
                width: 50,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            // Header de la modal avec close et icône restore
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, null),
                ),
                IconButton(
                  icon: Icon(Icons.restore),
                  onPressed: () {
                    setState(() {
                      _selectedEntity = EntityType.all;
                      _selectedDate = null;
                      _selectedGenreIds.clear();
                      _selectedCityOption = null;
                      _selectedEventType = null;
                      _selectedVenueType = null;
                    });
                  },
                ),
              ],
            ),
            _buildEntitySelection(), // Affiche "What are you looking for?" avec dropdown
            Divider(),
            // Affichage des filtres généraux avec titres de section
            if (_selectedEntity == EntityType.all) ...[
              _buildSectionTitle("DATE"),
              _buildDateField(),
              _buildSectionTitle("AREA"),
              Wrap(spacing: 6.0, children: _buildCityChips()),
              _buildSectionTitle("MOOD"),
              Wrap(spacing: 6.0, children: _buildGenreChips()),
            ]

            // Affichage des filtres spécifiques pour une entité
            else ...[
              if (_selectedEntity == EntityType.event) ...[
                _buildSectionTitle("DATE"),
                _buildDateField(),
                _buildSectionTitle("AREA"),
                Wrap(spacing: 6.0, children: _buildCityChips()),
                _buildSectionTitle("MOOD"),
                Wrap(spacing: 6.0, children: _buildGenreChips()),
              ] else if (_selectedEntity == EntityType.venue) ...[
                _buildSectionTitle("AREA"),
                Wrap(spacing: 6.0, children: _buildCityChips()),
                _buildSectionTitle("MOOD"),
                Wrap(spacing: 6.0, children: _buildGenreChips()),
              ] else if (_selectedEntity == EntityType.artist) ...[
                _buildSectionTitle("MOOD"),
                Wrap(spacing: 6.0, children: _buildGenreChips()),
              ] else if (_selectedEntity == EntityType.promoter) ...[
                _buildSectionTitle("MOOD"),
                Wrap(spacing: 6.0, children: _buildGenreChips()),
              ] else if (_selectedEntity == EntityType.genre) ...[
                _buildSectionTitle("MOOD"),
                Wrap(spacing: 6.0, children: _buildGenreChips()),
              ]
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              child: Text("Apply"),
              onPressed: () {
                SearchFilters newFilters = SearchFilters(
                  entityType: _selectedEntity,
                  date: _selectedDate,
                  genreIds: _selectedGenreIds,
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
                  eventType: _selectedEntity == EntityType.event
                      ? _selectedEventType
                      : null,
                  venueType: _selectedEntity == EntityType.venue
                      ? _selectedVenueType
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
}
