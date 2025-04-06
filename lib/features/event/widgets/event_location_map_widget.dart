import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:maps_launcher/maps_launcher.dart';

/// A widget that displays a non-interactive OpenStreetMap map with a marker at the event location.
/// The [location] parameter can be either a coordinate string in the format "latitude,longitude"
/// or an address that will be converted to coordinates using the geocoding package.
/// Tapping on the map launches an external maps application using the provided address.
class EventLocationMapWidget extends StatelessWidget {
  final String location;
  final double zoomLevel;

  const EventLocationMapWidget({
    required this.location,
    this.zoomLevel = 14.0,
    Key? key,
  }) : super(key: key);

  /// Attempts to retrieve a LatLng from the provided [location] string.
  Future<LatLng> _getLatLng() async {
    if (location.trim().isEmpty) {
      throw Exception("No location provided.");
    }
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
        // Fall back to geocoding if parsing fails.
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

  /// Launches the external maps application using the provided address.
  Future<void> _openMapByAddress() async {
    MapsLauncher.launchQuery(location);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

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
              border: Border.all(color: Colors.grey, width: 2.0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    "Address not compatible",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final latLng = snapshot.data!;
        return SizedBox(
          height: 200,
          child: Stack(
            children: [
              // The map display
              Container(
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
                        urlTemplate: tileUrl,
                        subdomains: const ['a', 'b', 'c', 'd'],
                        retinaMode: true,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80.0,
                            height: 80.0,
                            point: latLng,
                            child: Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.primary,
                              size: 40.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Transparent overlay to intercept taps.
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      try {
                        await _openMapByAddress();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
