// lib/features/event/widgets/event_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class EventListItemWidget extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final int maxTitleLength;

  const EventListItemWidget({
    required this.event,
    required this.onTap,
    this.maxTitleLength = 20,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Troncature du titre si nécessaire
    String truncatedTitle = event.title.length > maxTitleLength
        ? '${event.title.substring(0, maxTitleLength)}...'
        : event.title;

    final EventVenueService eventVenueService = EventVenueService();

    return ListTile(
      leading: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .onPrimary
                .withValues(alpha: 0.5), // Couleur de la bordure
            width: 2.0, // Épaisseur de la bordure
          ),
          borderRadius:
              BorderRadius.circular(12), // Coins arrondis de la bordure
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ImageWithErrorHandler(
            imageUrl: event.imageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        truncatedTitle,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: FutureBuilder<Venue?>(
        future: eventVenueService.getVenueByEventId(event.id),
        builder: (context, venueSnapshot) {
          if (venueSnapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          } else if (venueSnapshot.hasError) {
            return const Text(
              'Error loading venue',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            );
          } else if (!venueSnapshot.hasData || venueSnapshot.data == null) {
            return const Text(
              'Unknown location',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            );
          } else {
            final venue = venueSnapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        venue
                            .name, // Ou utilisez une autre propriété pertinente
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${formatEventDate(event.dateTime)}, ${formatEventTime(event.dateTime)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class EventCardItemWidget extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final int maxTitleLength;

  const EventCardItemWidget({
    required this.event,
    required this.onTap,
    this.maxTitleLength = 30, // Définissez la longueur maximale du titre ici
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Troncature du titre si nécessaire
    String truncatedTitle = event.title.length > maxTitleLength
        ? '${event.title.substring(0, maxTitleLength)}...'
        : event.title;

    final EventVenueService eventVenueService = EventVenueService();

    return GestureDetector(
      onTap: () {
        // Naviguer vers l'écran de détails de l'événement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventScreen(event: event),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de l'événement
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withValues(alpha: 0.5), // Couleur de la bordure
                    width: 2.0, // Épaisseur de la bordure
                  ),
                  borderRadius:
                      BorderRadius.circular(12), // Coins arrondis de la bordure
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImageWithErrorHandler(
                    imageUrl: event.imageUrl,
                    width: double.infinity,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de l'événement avec troncature
                    Text(
                      truncatedTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Date et heure
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${formatEventDate(event.dateTime)}, ${formatEventTime(event.dateTime)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Lieu (Nom du lieu récupéré via EventVenueService)
                    FutureBuilder<Venue?>(
                      future: eventVenueService.getVenueByEventId(event.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                'Loading...', // 'Venue loading...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          return const Text(
                            'Unknown location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          );
                        } else {
                          final venue = snapshot.data!;
                          return Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  venue.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              // Bouton ou autre info
              // Vous pouvez ajouter d'autres détails ou boutons ici
            ],
          ),
        ),
      ),
    );
  }
}
