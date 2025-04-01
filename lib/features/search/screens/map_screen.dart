// lib/screens/map_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
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
  bool _isLoading = false;
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
    _zoom = 13; // Niveau de zoom initial
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

  /// Récupère la liste des événements et pour chacun, récupère son Venue via le service.
  Future<void> _fetchEventsAndVenues() async {
    setState(() {
      _isLoading = true;
    });
    _radius = _calculateVisibleRadius();
    _lastFetchCenter = _center;
    try {
      List<Event> newEvents =
          await _eventVenueService.getEventsAround(_center, _radius);
      final DateTime now = DateTime.now();
      newEvents = newEvents.where((e) => e.eventDateTime.isAfter(now)).toList();
      // Pour chaque événement, si le venue n'est pas déjà en cache, le récupérer
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
      debugPrint("Erreur lors du chargement des événements ou des venues: $e");
    } finally {
      setState(() {
        _isLoading = false;
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
      builder: (_) => EventCardItemWidget(
        event: event,
        onTap: () => _onMarkerTapped(event, venue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Map'),
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
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  disableClusteringAtZoom: 16,
                  size: const Size(40, 40),
                  padding: const EdgeInsets.all(50),
                  builder: (context, markers) {
                    return Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.redAccent,
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
                          width: 40,
                          height: 40,
                          point: LatLng(lat, lon),
                          child: IconButton(
                            icon: const Icon(Icons.location_on,
                                color: Colors.red),
                            iconSize: 40,
                            onPressed: () => _onMarkerTapped(
                                event,
                                Venue(
                                  id: meta['venue_id'],
                                  name: meta['venue_name'],
                                  imageUrl: '',
                                  description: '',
                                  location: '',
                                  isVerified: false,
                                  latitude: lat,
                                  longitude: lon,
                                )),
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
      floatingActionButton:
          _isLoading ? const CircularProgressIndicator() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
