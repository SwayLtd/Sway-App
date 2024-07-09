import 'package:flutter/material.dart';
import 'package:sway_events/features/event/event.dart';
import 'package:sway_events/features/event/models/event_model.dart';
import 'package:sway_events/features/venue/services/venue_service.dart';

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    DateTime eventDateTime = DateTime.parse(event.dateTime);

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
                  child: Image.network(
                    event.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FutureBuilder(
                        future: VenueService().getVenueById(event.venue),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text(
                              'Loading...',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            );
                          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                            return Text(
                              'Location not found',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            );
                          } else {
                            final venue = snapshot.data!;
                            return Text(
                              venue.name,
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
                              style: const TextStyle(fontSize: 14, color: Colors.red),
                            ),
                            const TextSpan(
                              text: ' | ',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            TextSpan(
                              text: _formatEventTime(eventDateTime),
                              style: const TextStyle(fontSize: 14, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        event.price,
                        style: const TextStyle(fontSize: 14, color: Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _buildGenreChips(event.genres, context),
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
    if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day) {
      return 'Today';
    } else if (dateTime.year == now.year && dateTime.month == now.month && dateTime.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return '${_getWeekdayName(dateTime.weekday)} ${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatEventTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  List<Widget> _buildGenreChips(List<String> genres, BuildContext context) {
    List<Widget> chips = [];
    double totalWidth = 0;
    double maxWidth = MediaQuery.of(context).size.width - 60; // Adjust according to card padding

    for (int i = 0; i < genres.length; i++) {
      final textPainter = TextPainter(
        text: TextSpan(text: genres[i], style: const TextStyle(fontSize: 12)),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();

      totalWidth += textPainter.width + 20; // 20 for padding and margin

      if (totalWidth > maxWidth) {
        chips.add(Chip(label: Text('+${genres.length - i}')));
        break;
      } else {
        chips.add(Chip(label: Text(genres[i])));
      }
    }
    return chips;
  }
}
