import 'package:sway/features/event/models/event_model.dart';

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
    final promoterEvents = events
        .where((event) => event.promoters.contains(json['id']))
        .map((e) => e.id)
        .toList();

    return Promoter(
      id: json['id'] ?? 0, // Assure-toi que l'id ne soit pas null
      name: json['name'] as String? ??
          '', // Si le nom est null, remplace-le par une chaîne vide
      imageUrl:
          json['image_url'] as String? ?? '', // Remplace null par une URL vide
      description: json['description'] as String? ??
          '', // Remplace null par une chaîne vide
      upcomingEvents: promoterEvents,
    );
  }

  factory Promoter.fromJsonWithoutEvents(Map<String, dynamic> json) {
    return Promoter(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      upcomingEvents: [],
    );
  }
}
