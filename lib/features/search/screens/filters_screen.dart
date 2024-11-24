import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';

class FiltersScreen extends StatefulWidget {
  final Map<String, dynamic> filters;

  const FiltersScreen({required this.filters});

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late List<String> _selectedCities;
  late DateTime? _selectedDate;
  late List<String> _selectedVenueTypes;
  late List _selectedGenres;
  late bool _nearMe;

  final List<String> venueTypes = [
    'Festival',
    'Nightclub',
    'Bar',
    'Concert Hall',
    'Open Air',
  ];

  int _visibleCityCount = 10;
  int _visibleVenueTypeCount = 10;
  int _visibleGenreCount = 10;

  @override
  void initState() {
    super.initState();
    _selectedCities = List<String>.from((widget.filters['cities'] ?? []) as Iterable);
    _selectedDate = widget.filters['date'] as DateTime?;
    _selectedVenueTypes = List<String>.from((widget.filters['venueTypes'] ?? []) as Iterable);
    _selectedGenres = List.from((widget.filters['genres'] ?? []));
    _nearMe = widget.filters['near_me'] as bool;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Widget _buildCityChips() {
    final List<String> cities = [
      'Near Me',
      'New York',
      'Los Angeles',
      'Chicago',
      'Houston',
      'San Francisco',
      'Miami',
      'Boston',
      'Seattle',
      'Denver',
      'Atlanta',
    ];

    final visibleCities = cities.take(_visibleCityCount).toList();
    final remainingCities = cities.length - visibleCities.length;

    return Wrap(
      spacing: 8.0,
      children: [
        ...visibleCities.map((city) {
          return ChoiceChip(
            label: Text(city),
            selected: _nearMe ? city == 'Near Me' : _selectedCities.contains(city),
            onSelected: (bool selected) {
              setState(() {
                if (city == 'Near Me') {
                  _nearMe = selected;
                  if (selected) {
                    _selectedCities.clear();
                  }
                } else {
                  _nearMe = false;
                  if (selected) {
                    _selectedCities.add(city);
                  } else {
                    _selectedCities.remove(city);
                  }
                }
              });
            },
          );
        }),
        if (remainingCities > 0)
          ChoiceChip(
            label: const Text('...'),
            selected: false,
            onSelected: (bool selected) {
              setState(() {
                _visibleCityCount += 10;
              });
            },
          ),
      ],
    );
  }

  Widget _buildGenreChips() {
    return FutureBuilder<List<Genre>>(
      future: GenreService().getGenres(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading genres'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No genres available'));
        } else {
          final genres = snapshot.data!;
          final visibleGenres = genres.take(_visibleGenreCount).toList();
          final remainingGenres = genres.length - visibleGenres.length;

          return Wrap(
            spacing: 8.0,
            children: [
              ...visibleGenres.map((genre) {
                return ChoiceChip(
                  label: Text(genre.name),
                  selected: _selectedGenres.contains(genre.id),
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedGenres.add(genre.id);
                      } else {
                        _selectedGenres.remove(genre.id);
                      }
                    });
                  },
                );
              }),
              if (remainingGenres > 0)
                ChoiceChip(
                  label: const Text('...'),
                  selected: false,
                  onSelected: (bool selected) {
                    setState(() {
                      _visibleGenreCount += 10;
                    });
                  },
                ),
            ],
          );
        }
      },
    );
  }

  Widget _buildVenueTypeChips() {
    final visibleVenueTypes = venueTypes.take(_visibleVenueTypeCount).toList();
    final remainingVenueTypes = venueTypes.length - visibleVenueTypes.length;

    return Wrap(
      spacing: 8.0,
      children: [
        ...visibleVenueTypes.map((type) {
          return ChoiceChip(
            label: Text(type),
            selected: _selectedVenueTypes.contains(type),
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  _selectedVenueTypes.add(type);
                } else {
                  _selectedVenueTypes.remove(type);
                }
              });
            },
          );
        }),
        if (remainingVenueTypes > 0)
          ChoiceChip(
            label: const Text('...'),
            selected: false,
            onSelected: (bool selected) {
              setState(() {
                _visibleVenueTypeCount += 10;
              });
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _selectedCities.clear();
                _selectedDate = null;
                _selectedVenueTypes.clear();
                _selectedGenres.clear();
                _nearMe = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, {
                'cities': _selectedCities,
                'date': _selectedDate,
                'venueTypes': _selectedVenueTypes,
                'genres': _selectedGenres,
                'near_me': _nearMe,
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildSectionTitle('Date'),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(
                _selectedDate != null
                    ? DateFormat.yMMMd().format(_selectedDate!)
                    : 'Select a date',
              ),
              onTap: () {
                _selectDate(context);
              },
            ),
            _buildSectionTitle('Location'),
            _buildCityChips(),
            _buildSectionTitle('Venue Type'),
            _buildVenueTypeChips(),
            _buildSectionTitle('Genre'),
            _buildGenreChips(),
          ],
        ),
      ),
    );
  }
}
