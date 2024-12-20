// lib/features/event/widgets/event_card.dart

import 'package:flutter/material.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({required this.event, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Container(
          width: 280, // Ajustez la largeur selon vos besoins
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image de l'événement
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary, // Couleur de la bordure
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
              // Titre de l'événement
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Date et heure
              Text(
                '${event.dateTime.toLocal()}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              // Lieu (Nom du lieu récupéré via EventVenueService)
              FutureBuilder<Venue?>(
                future: EventVenueService().getVenueByEventId(event.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text(
                      'Chargement du lieu...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    );
                  } else if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data == null) {
                    return const Text(
                      'Lieu inconnu',
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
              // Bouton ou autre info
              // Vous pouvez ajouter d'autres détails ou boutons ici
            ],
          ),
        ),
      ),
    );
  }
}
