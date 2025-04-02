// lib/screens/map_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/event/widgets/event_item_widget.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class MapScreen extends StatefulWidget {
  final LatLng initialCenter;
  const MapScreen({required this.initialCenter, Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final MapController _mapController;
  late LatLng _center;
  late double _zoom;
  double _radius = 20000; // Rayon initial de 10 km en mètres
  List<Event> _eventsCache = [];
  // Cache associant l'ID de l'Event à son Venue
  Map<int, Venue> _venuesCacheMap = {};
  final Set<int> _loadedEventIds =
      {}; // Pour éviter les doublons (basé sur l'ID de l'event)
  DateTime? _selectedDate;

  // bool _isLoading = false;
  LatLng? _lastFetchCenter;
  Timer? _debounceTimer;
  double _mapWidth = 0;
  double _mapHeight = 0;
  final EventVenueService _eventVenueService = EventVenueService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = widget.initialCenter;
    _zoom = 12; // Niveau de zoom initial
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Calcule le rayon visible en mètres en fonction de la taille de la carte et du zoom
  double _calculateVisibleRadius() {
    if (_mapWidth == 0 || _mapHeight == 0) {
      return _radius;
    }
    final double metersPerPixel = 156543.03392 *
        (math.cos(_center.latitude * math.pi / 180)) /
        math.pow(2, _zoom);
    final double halfDiagonalPx =
        math.sqrt(math.pow(_mapWidth / 2, 2) + math.pow(_mapHeight / 2, 2));
    double visibleRadius = halfDiagonalPx * metersPerPixel;
    visibleRadius *= 1.1; // Marge de 10%
    return visibleRadius;
  }

  // Helper function to compare only date parts
  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Récupère la liste des événements et pour chacun, récupère son Venue via le service.
  Future<void> _fetchEventsAndVenues() async {
    setState(() {
      // _isLoading = true;
      // Clear the caches so that the list is refreshed
      _eventsCache.clear();
      _loadedEventIds.clear();
      _venuesCacheMap.clear();
    });

    _radius = _calculateVisibleRadius();
    _lastFetchCenter = _center;
    try {
      List<Event> newEvents =
          await _eventVenueService.getEventsAround(_center, _radius);
      final DateTime now = DateTime.now();

      if (_selectedDate != null) {
        // Filter events occurring on the selected date, ignoring the current time
        newEvents = newEvents
            .where((e) => _isSameDate(e.eventDateTime, _selectedDate!))
            .toList();
      } else {
        // Only show future events if no date is selected
        newEvents =
            newEvents.where((e) => e.eventDateTime.isAfter(now)).toList();
      }

      // For each event, if not cached, fetch its associated venue
      for (var event in newEvents) {
        if (event.id == null) continue;
        if (!_loadedEventIds.contains(event.id)) {
          _loadedEventIds.add(event.id!);
          Venue? venue = await _eventVenueService.getVenueByEventId(event.id!);
          if (venue != null) {
            _venuesCacheMap[event.id!] = venue;
          }
          _eventsCache.add(event);
        }
      }
    } catch (e) {
      debugPrint("Error fetching events or venues: $e");
    } finally {
      setState(() {
        // _isLoading = false;
      });
    }
  }

  /// Callback lors du changement de position (déplacement ou zoom)
  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    _center = camera.center;
    _zoom = camera.zoom;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (_lastFetchCenter != null) {
        final distanceMoved =
            Distance().as(LengthUnit.Meter, _lastFetchCenter!, _center);
        if (distanceMoved < _radius * 0.3) {
          return;
        }
      }
      _fetchEventsAndVenues();
    });
  }

  /// Lorsqu'un marker est tapé, affiche le détail de l'événement via un BottomSheet.
  /// Vous pouvez adapter ce widget pour afficher également les infos du venue.
  void _onMarkerTapped(Event event, Venue venue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final containerColor = isDark ? Colors.grey[900] : Colors.white;

        return Padding(
          padding: EdgeInsets.only(bottom: screenHeight * 0.05),
          child: FractionallySizedBox(
            heightFactor: 0.30,
            child: Center(
              child: Container(
                width: 320,
                decoration: BoxDecoration(
                  color: containerColor, // Couleur de fond selon le mode
                  borderRadius: BorderRadius.circular(16.0), // Bords arrondis
                ),
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
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return Scaffold(
      extendBodyBehindAppBar: true, // To place the card behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar icon with date picker
            IconButton(
              icon: Icon(
                _selectedDate != null ? Icons.event_busy : Icons.event,
              ),
              onPressed: () async {
                // If a date is already selected, reset it; otherwise, show the date picker.
                if (_selectedDate != null) {
                  setState(() {
                    _selectedDate = null;
                  });
                  _fetchEventsAndVenues(); // Refresh events without date filter
                } else {
                  final selectedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: const Locale('en',
                        'GB'), // Week starts on Monday in Great-Britain locale
                  );

                  if (selectedDate != null) {
                    setState(() {
                      _selectedDate = selectedDate;
                    });
                    _fetchEventsAndVenues(); // Refresh events with new date filter
                  }
                }
              },
            ),

            // Display selected date in short format if available
            if (_selectedDate != null)
              Text(
                // Format the date as "dd MMM", e.g., "17 Apr"
                DateFormat('dd MMM').format(_selectedDate!),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          _mapWidth = constraints.maxWidth;
          _mapHeight = constraints.maxHeight;
          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              minZoom: 5,
              maxZoom: 18,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: _onPositionChanged,
              onMapReady: () {
                _fetchEventsAndVenues();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                retinaMode: true,
              ),
              // Uncomment this if you want to show a circle around the center point
              /* CircleLayer(
                circles: [
                  CircleMarker(
                    point: _center,
                    radius: _radius, // en mètres (useRadiusInMeter: true)
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderStrokeWidth: 2,
                    borderColor: Colors.blueAccent,
                  ),
                ],
              ), */
              // Ajout du layer de localisation actuelle
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        width: 2,
                      ),
                    ),
                  ),
                  markerSize: const Size.square(20),
                  accuracyCircleColor:
                      Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  // Hide the heading sector by setting its radius to 0 and its color to transparent
                  headingSectorRadius: 0,
                  headingSectorColor: Colors.transparent,
                  // Alternatively, if supported:
                  // markerDirection: MarkerDirection.none,
                ),
                moveAnimationDuration: Duration.zero, // disable animation
              ),

              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  disableClusteringAtZoom: 16,
                  size: const Size(40, 40),
                  padding: const EdgeInsets.all(50),
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: Center(
                        child: Text(
                          "${markers.length}",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    );
                  },
                  markers: _eventsCache
                      .map((event) {
                        final meta = event.metadata;
                        if (meta == null ||
                            meta['venue_latitude'] == null ||
                            meta['venue_longitude'] == null) {
                          return null;
                        }
                        final lat = meta['venue_latitude'];
                        final lon = meta['venue_longitude'];
                        final distance = Distance().as(
                          LengthUnit.Meter,
                          _center,
                          LatLng(lat, lon),
                        );
                        if (distance > _radius) return null;
                        return Marker(
                          width: 90, // 16:9 format: 90x50 for the image
                          height:
                              90, // Total size to contain image (and optionally label)
                          point: LatLng(lat, lon),
                          child: GestureDetector(
                            onTap: () => _onMarkerTapped(
                              event,
                              Venue(
                                id: meta['venue_id'],
                                name: meta['venue_name'],
                                imageUrl: '',
                                description: '',
                                location: '',
                                isVerified: false,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 90,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey, width: 1),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: ImageWithErrorHandler(
                                      imageUrl: event.imageUrl,
                                      width: 90,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // The venue name container has been removed.
                              ],
                            ),
                          ),
                        );
                      })
                      .whereType<Marker>()
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent, // Fond transparent
        elevation: 0, // Sans ombre
        onPressed: () {
          // Réinitialiser la position et le zoom de la carte
          _mapController.move(
              widget.initialCenter, 12); // Ici, 12 est le zoom initial
        },
        child: const Icon(Icons.my_location),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
