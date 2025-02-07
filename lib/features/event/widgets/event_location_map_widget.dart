// lib/features/event/widgets/event_location_map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

/// A widget that displays a non-interactive OpenStreetMap map with a marker at the event location.
/// The [location] can be provided as a string in the format "latitude,longitude"
/// or as an address that will be converted to coordinates using geocoding.
class EventLocationMapWidget extends StatelessWidget {
  final String location;
  final double zoomLevel;

  const EventLocationMapWidget({
    required this.location,
    this.zoomLevel = 14.0,
    Key? key,
  }) : super(key: key);

  /// Retrieves a LatLng from the provided location string.
  /// If the string contains a comma, it is parsed as "latitude,longitude".
  /// Otherwise, it is treated as an address and converted to coordinates using geocoding.
  Future<LatLng> _getLatLng() async {
    if (location.contains(',')) {
      try {
        final parts = location.split(',');
        if (parts.length != 2) {
          throw Exception("Invalid location format");
        }
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      } catch (e) {
        return const LatLng(0, 0);
      }
    } else {
      try {
        List<Location> locations = await locationFromAddress(location);
        if (locations.isNotEmpty) {
          return LatLng(locations.first.latitude, locations.first.longitude);
        }
        return const LatLng(0, 0);
      } catch (e) {
        return const LatLng(0, 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _getLatLng(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text("Location not available")),
          );
        }
        final latLng = snapshot.data!;
        return SizedBox(
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimary
                    .withValues(alpha: 0.5),
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: latLng,
                  initialZoom: zoomLevel,
                  interactionOptions: const InteractionOptions(
                    flags: 0, // disable all interactions
                  ),
                ),
                children: [
                  TileLayer(
                    // Using the official OSM tile URL without subdomains.
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: latLng,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
