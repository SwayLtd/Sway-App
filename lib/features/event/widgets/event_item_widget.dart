// lib/features/event/widgets/event_item_widget.dart

import 'package:flutter/material.dart';
import 'package:sway/core/utils/date_utils.dart';
import 'package:sway/core/widgets/image_with_error_handler.dart';
import 'package:sway/features/event/event.dart';
import 'package:sway/features/event/models/event_model.dart';
import 'package:sway/features/event/services/event_genre_service.dart';
import 'package:sway/features/event/services/event_venue_service.dart';
import 'package:sway/features/genre/models/genre_model.dart';
import 'package:sway/features/genre/services/genre_service.dart';
import 'package:sway/features/venue/models/venue_model.dart';
import 'package:sway/core/utils/text_formatting.dart';
import 'package:sway/features/user/services/user_interest_event_service.dart';

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
            color:
                Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
            width: 2.0, // Épaisseur de la bordure
          ),
          borderRadius:
              BorderRadius.circular(12), // Coins arrondis de la bordure
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
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
        future: eventVenueService.getVenueByEventId(event.id!),
        builder: (context, venueSnapshot) {
          if (venueSnapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: SizedBox.shrink(),
            );
          } else if (venueSnapshot.hasError) {
            // On affiche la date et "Error loading venue" si erreur
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${formatEventDate(event.eventDateTime)}, ${formatEventTime(event.eventDateTime)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: const Text(
                        'Error loading venue',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else if (!venueSnapshot.hasData || venueSnapshot.data == null) {
            // On affiche la date et "Unknown location" quand aucune location n'est trouvée
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${formatEventDate(event.eventDateTime)}, ${formatEventTime(event.eventDateTime)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: const Text(
                        'Unknown location',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            );
          } else {
            final venue = venueSnapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${formatEventDate(event.eventDateTime)}, ${formatEventTime(event.eventDateTime)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
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
                        venue.name,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
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
        elevation: 0,
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
                        .withValues(alpha: 0.5),
                    width: 2.0,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      ImageWithErrorHandler(
                        imageUrl: event.imageUrl,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      // Positioned overlay for genres at the bottom of the image
                      // Inside the Stack of your EventCardItemWidget (replace the existing overlay Container):
                      Positioned(
                        left: 4,
                        right: 4,
                        bottom: 4,
                        child: FutureBuilder<List<int>>(
                          future:
                              EventGenreService().getGenresByEventId(event.id!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting ||
                                !snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            } else {
                              final genreIds = snapshot.data!;
                              const int maxDisplay = 3;
                              final int count = genreIds.length;
                              final int displayCount =
                                  count > maxDisplay ? maxDisplay : count;
                              List<Widget> chips = [];
                              for (int i = 0; i < displayCount; i++) {
                                chips.add(EventGenreChip(genreId: genreIds[i]));
                                chips.add(const SizedBox(width: 4));
                              }
                              if (count > maxDisplay) {
                                chips.add(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${count - maxDisplay}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                alignment: Alignment.centerRight,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: chips,
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
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
                        Expanded(
                          child: Text(
                            '${formatEventDate(event.eventDateTime)}, ${formatEventTime(event.eventDateTime)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Lieu (Nom du lieu récupéré via EventVenueService)
                    FutureBuilder<Venue?>(
                      future: eventVenueService.getVenueByEventId(event.id!),
                      builder: (context, snapshot) {
                        String venueText;
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          venueText = 'Loading';
                        } else if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data == null) {
                          venueText = 'Unknown location';
                        } else {
                          venueText = snapshot.data!.name;
                        }
                        return Row(
                          children: [
                            // Partie gauche : la venue
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      venueText,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Partie droite : le nombre de participants "going"
                            FutureBuilder<int>(
                              future: UserInterestEventService()
                                  .getEventInterestCount(event.id!, 'going'),
                              builder: (context, countSnapshot) {
                                if (countSnapshot.connectionState ==
                                        ConnectionState.waiting ||
                                    !countSnapshot.hasData ||
                                    countSnapshot.data! <= 0) {
                                  return const SizedBox.shrink();
                                }
                                final formattedCount =
                                    formatNumber(countSnapshot.data!);
                                return Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedCount,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
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

class EventGenreChip extends StatelessWidget {
  final int genreId;
  const EventGenreChip({required this.genreId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Genre?>(
      future: GenreService().getGenreById(genreId),
      builder: (context, snapshot) {
        String genreName;
        if (snapshot.connectionState == ConnectionState.waiting) {
          genreName = '...';
        } else if (snapshot.hasError || snapshot.data == null) {
          genreName = 'Unknown';
        } else {
          genreName = snapshot.data!.name;
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            genreName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
