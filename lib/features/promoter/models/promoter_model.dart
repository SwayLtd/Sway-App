// lib/features/promoter/models/promoter_model.dart

import 'package:sway/features/event/models/event_model.dart';

class Promoter {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final List<int> upcomingEvents; // Rendre non-nullable
  final bool isVerified; // New property to indicate verification status

  Promoter({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    this.upcomingEvents = const [], // Valeur par défaut
    this.isVerified = false,
  });

  /// Création à partir de JSON avec événements
  factory Promoter.fromJson(Map<String, dynamic> json, List<Event> events) {
    // Extraire les IDs des événements
    final List<int> eventIds =
        events.map((event) => event.id).whereType<int>().toList();

    return Promoter(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      upcomingEvents: eventIds,
      isVerified: json['is_verified'] as bool? ??
          false, // Extract the verification status
    );
  }

  /// Création à partir de JSON sans événements
  factory Promoter.fromJsonWithoutEvents(Map<String, dynamic> json) {
    return Promoter(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      upcomingEvents: [], // Initialise à une liste vide
    );
  }

  /// Convertit l'objet en JSON pour l'insertion/mise à jour
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      // 'upcoming_events' n'est pas inclus car ce n'est pas une colonne directe dans la table 'promoters'
      'is_verified': isVerified, // Include the verification status
    };
  }

  /// Permet de créer une copie de l'objet avec des modifications
  Promoter copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    List<int>? upcomingEvents,
    bool? isVerified,
  }) {
    return Promoter(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
