// lib/features/event/models/event_model.dart

import 'dart:convert';

class Event {
  final int? id;
  final String title;
  final String type;
  final DateTime eventDateTime;
  final DateTime eventEndDateTime;
  final int? venue;
  final String description;
  final String imageUrl;
  final List<int>? promoters;
  final List<int>? genres;
  final List<int>? artists;
  final int? interestedUsersCount;
  final Map<String, dynamic>? metadata;

  Event({
    this.id,
    required this.title,
    required this.type,
    required this.eventDateTime,
    required this.eventEndDateTime,
    this.venue,
    required this.description,
    required this.imageUrl,
    this.promoters,
    this.genres,
    this.artists,
    this.interestedUsersCount,
    this.metadata,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? decodedMetadata;

    if (json['metadata'] is String && (json['metadata'] as String).isNotEmpty) {
      try {
        decodedMetadata = jsonDecode(json['metadata']) as Map<String, dynamic>;
      } catch (e) {
        print("Erreur lors du décodage de metadata : $e");
      }
    } else if (json['metadata'] is Map<String, dynamic>) {
      decodedMetadata = json['metadata'] as Map<String, dynamic>;
    }

    return Event(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      eventDateTime: DateTime.parse(json['date_time'] as String),
      eventEndDateTime: DateTime.parse(json['end_date_time'] as String),
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      promoters: (json['promoters'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      genres:
          (json['genres'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      artists:
          (json['artists'] as List<dynamic>?)?.map((e) => e as int).toList() ??
              [],
      interestedUsersCount: json['interested_users_count'] as int?,
      metadata: decodedMetadata ??
          {}, // Assurez-vous de ne jamais laisser metadata être null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type': type,
      'date_time': eventDateTime.toIso8601String(),
      'end_date_time': eventEndDateTime.toIso8601String(),
      // 'venue': venue,
      'description': description,
      'image_url': imageUrl,
      // 'distance': distance,
      // 'promoters': promoters,
      // 'genres': genres,
      // 'artists': artists,
      // 'interested_users_count': interestedUsersCount,
      'metadata': metadata,
    };
  }

  // Added copyWith method to create modified copies of an Event
  Event copyWith({
    int? id,
    String? title,
    String? type,
    DateTime? eventDateTime,
    DateTime? eventEndDateTime,
    int? venue,
    String? description,
    String? imageUrl,
    String? distance,
    List<int>? promoters,
    List<int>? genres,
    List<int>? artists,
    int? interestedUsersCount,
    Map<String, dynamic>? metadata,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      eventDateTime: eventDateTime ?? this.eventDateTime,
      eventEndDateTime: eventEndDateTime ?? this.eventEndDateTime,
      venue: venue ?? this.venue,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      promoters: promoters ?? this.promoters,
      genres: genres ?? this.genres,
      artists: artists ?? this.artists,
      interestedUsersCount: interestedUsersCount ?? this.interestedUsersCount,
      metadata: metadata ?? this.metadata,
    );
  }
}
