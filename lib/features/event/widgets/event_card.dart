// event_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sway_events/features/event/services/event_genre_service.dart';
import 'package:sway_events/features/genre/widgets/genre_chip.dart';
import 'package:sway_events/core/widgets/image_with_error_handler.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';
import 'package:sway_events/features/user/services/user_interest_event_service.dart';

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
        color: Theme.of(context).cardColor, // Utilisation de la couleur de fond de la carte du thème
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
                      Icons.play_arrow,
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
                  child: FutureBuilder<Map<String, bool>>(
                    future: _getEventStatus(event.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Icon(Icons.favorite_border, size: 30, color: Colors.white);
                      } else if (snapshot.hasError) {
                        return const Icon(Icons.error, size: 30, color: Colors.white);
                      } else {
                        final bool isInterested = snapshot.data?['isInterested'] ?? false;
                        final bool isAttended = snapshot.data?['isAttended'] ?? false;
                        return Row(
                          children: [
                            PopupMenuButton<String>(
                              icon: Icon(
                                isAttended
                                    ? Icons.check_circle
                                    : (isInterested
                                        ? Icons.favorite
                                        : Icons.favorite_border),
                                size: 30,
                                color: Colors.white,
                              ),
                              onSelected: (String value) {
                                _handleMenuSelection(value, event.id, isInterested, isAttended);
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'interested',
                                  child: Text('Interested'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'going',
                                  child: Text('Going'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'ignored',
                                  child: Text(isInterested || isAttended ? 'Not going' : 'Not interested'),
                                ),
                              ],
                            ),
                            FutureBuilder<int>(
                              future: UserInterestEventService().getEventInterestCount(event.id, 'both'),
                              builder: (context, countSnapshot) {
                                if (countSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Text(
                                    '...',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  );
                                } else if (countSnapshot.hasError) {
                                  return const Text(
                                    '0',
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  );
                                } else {
                                  return Text(
                                    '${countSnapshot.data}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  );
                                }
                              },
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: Colors.grey,
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder(
                        future: VenueService().getVenueById(event.venue),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            );
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data == null) {
                            return const Text(
                              'Location not found',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            );
                          } else {
                            final venue = snapshot.data!;
                            return Text(
                              venue.name,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            );
                          }
                        },
                      ),
                      Text(
                        event.distance,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                            const TextSpan(
                              text: ' | ',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            TextSpan(
                              text: _formatEventTime(eventDateTime),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        event.price,
                        style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<String>>(
                    future: EventGenreService().getGenresByEventId(event.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No genres found');
                      } else {
                        final genres = snapshot.data!;
                        return Wrap(
                          spacing: 8.0,
                          children: genres.map((genreId) => GenreChip(genreId: genreId)).toList(),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, bool>> _getEventStatus(String eventId) async {
    bool isInterested = await UserInterestEventService().isInterestedInEvent(eventId);
    bool isAttended = await UserInterestEventService().isAttendedEvent(eventId);
    return {'isInterested': isInterested, 'isAttended': isAttended};
  }

  void _handleMenuSelection(String value, String eventId, bool isInterested, bool isAttended) {
    switch (value) {
      case 'interested':
        UserInterestEventService().addInterest(eventId);
        break;
      case 'going':
        UserInterestEventService().markEventAsAttended(eventId);
        break;
      case 'ignored':
        if (isInterested || isAttended) {
          UserInterestEventService().removeInterest(eventId);
        } else {
          UserInterestEventService().removeInterest(eventId);
        }
        break;
    }
  }

  String _formatEventDate(DateTime dateTime) {
    final now = DateTime.now();
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return 'Today';
    } else if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return DateFormat.yMMMMEEEEd().format(dateTime);
    }
  }

  String _formatEventTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
