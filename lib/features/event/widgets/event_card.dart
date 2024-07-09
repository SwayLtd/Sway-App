import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/core/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final DateTime eventDateTime = DateTime.parse(event.dateTime);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventScreen(event: event),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        margin: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                  child: ImageWithErrorHandler(
                    imageUrl: event.imageUrl,
                    width: double.infinity,
                    height: 200,
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.play_circle_filled,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Play button action
                    },
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      size: 30,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      // Like button action
                    },
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder(
                        future: VenueService().getVenueById(event.venue),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey,),
                            );
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const Text(
                              'Location not found',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey,),
                            );
                          } else {
                            final venue = snapshot.data!;
                            return Text(
                              venue.name,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey,),
                            );
                          }
                        },
                      ),
                      Text(
                        event.distance,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatEventDate(eventDateTime),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.red,),
                            ),
                            const TextSpan(
                              text: ' | ',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            TextSpan(
                              text: _formatEventTime(eventDateTime),
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.red,),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        event.price,
                        style:
                            const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8.0,
                    children: event.genres.map((genreId) {
                      return GenreChip(genreId: genreId);
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      return 'Today';
    } else if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return DateFormat.yMMMMEEEEd().format(dateTime); // Format readable by humans
    }
  }

  String _formatEventTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
