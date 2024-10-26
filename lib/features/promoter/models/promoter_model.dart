// lib/features/promoter/models/promoter_model.dart

import 'package:sway/features/event/models/event_model.dart';

class Promoter {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final List<int> upcomingEvents;

  Promoter({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.upcomingEvents,
  });

  factory Promoter.fromJson(Map<String, dynamic> json, List<Event> events) {
    // Extraire les IDs des événements
    final List<int> eventIds = events.map((event) => event.id).toList();

    return Promoter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      upcomingEvents: eventIds,
    );
  }

  factory Promoter.fromJsonWithoutEvents(Map<String, dynamic> json) {
    return Promoter(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      upcomingEvents: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'upcoming_events': upcomingEvents, // Optionnel si nécessaire
    };
  }

  Promoter copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    List<int>? upcomingEvents,
  }) {
    return Promoter(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
    );
  }
}
