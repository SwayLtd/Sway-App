// lib/features/event/widgets/event_location_map_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

/// A widget that displays a non-interactive OpenStreetMap map with a marker at the event location.
/// The [location] parameter can be either a coordinate string in the format "latitude,longitude"
/// or an address that will be converted to coordinates using the geocoding package.
/// If geocoding fails or no valid coordinates are obtained, an error message is displayed.
class EventLocationMapWidget extends StatelessWidget {
  final String location;
  final double zoomLevel;

  const EventLocationMapWidget({
    required this.location,
    this.zoomLevel = 14.0,
    Key? key,
  }) : super(key: key);

  /// Attempts to retrieve a LatLng from the provided [location] string.
  /// If the string contains a comma, it is parsed as "latitude,longitude".
  /// Otherwise, it calls [locationFromAddress] to geocode the address.
  /// Throws an exception if no valid coordinates are obtained.
  Future<LatLng> _getLatLng() async {
    if (location.trim().isEmpty) {
      throw Exception("No location provided.");
    }
    // If the location contains a comma, attempt to parse it as coordinates.
    if (location.contains(',')) {
      try {
        final parts = location.split(',');
        if (parts.length != 2) {
          throw Exception("Invalid coordinate format.");
        }
        final lat = double.parse(parts[0].trim());
        final lng = double.parse(parts[1].trim());
        return LatLng(lat, lng);
      } catch (e) {
        // If parsing fails, fall back to geocoding.
      }
    }
    try {
      final locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      throw Exception("No coordinates found for the address.");
    } catch (e) {
      throw Exception("Error converting address: $e");
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
        if (snapshot.hasError) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                "Location not available",
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
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
                    flags: 0, // Disable all interactions.
                  ),
                ),
                children: [
                  TileLayer(
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
