import 'package:sway_events/features/event/models/event_model.dart';

class Promoter {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final List upcomingEvents;

  Promoter({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.upcomingEvents,
  });

  factory Promoter.fromJson(Map<String, dynamic> json, List<Event> events) {
    // Filtrer les événements par promoterId
    final promoterEvents = events.where((event) => event.promoters.contains(json['id'])).map((e) => e.id).toList();

    return Promoter(
      id: json['id'],
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      upcomingEvents: promoterEvents,
    );
  }

  factory Promoter.fromJsonWithoutEvents(Map<String, dynamic> json) {
    return Promoter(
      id: json['id'],
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      upcomingEvents: [],
    );
  }
}
