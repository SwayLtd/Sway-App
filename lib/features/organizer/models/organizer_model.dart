import 'package:sway_events/features/event/models/event_model.dart';

class Organizer {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> upcomingEvents;

  Organizer({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.upcomingEvents,
  });

  factory Organizer.fromJson(Map<String, dynamic> json, List<Event> events) {
    // Filtrer les événements par organizerId
    final organizerEvents = events.where((event) => event.organizers.contains(json['id'])).map((e) => e.id).toList();

    return Organizer(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      upcomingEvents: organizerEvents,
    );
  }

  factory Organizer.fromJsonWithoutEvents(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      upcomingEvents: [],
    );
  }
}
