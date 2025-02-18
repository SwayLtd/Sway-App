// lib/features/event/models/event_model.dart

class Event {
  final int? id;
  final String title;
  final String type;
  final DateTime eventDateTime;
  final DateTime eventEndDateTime;
  final int? venue;
  final String description;
  final String imageUrl;
  final String? price;
  final List<int>? promoters;
  final List<int>? genres;
  final List<int>? artists;
  final int? interestedUsersCount;

  Event({
    this.id,
    required this.title,
    required this.type,
    required this.eventDateTime,
    required this.eventEndDateTime,
    this.venue,
    required this.description,
    required this.imageUrl,
    this.price,
    this.promoters,
    this.genres,
    this.artists,
    this.interestedUsersCount,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int?,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      eventDateTime: DateTime.parse(json['date_time'] as String),
      eventEndDateTime: DateTime.parse(json['end_date_time'] as String),
      // venue: json['venue'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      // distance: json['distance'] as String? ?? '',
      // price: json['price'] as String? ?? '',
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
      // 'price': price,
      // 'promoters': promoters,
      // 'genres': genres,
      // 'artists': artists,
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
    String? price,
    List<int>? promoters,
    List<int>? genres,
    List<int>? artists,
    int? interestedUsersCount,
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
      price: price ?? this.price,
      promoters: promoters ?? this.promoters,
      genres: genres ?? this.genres,
      artists: artists ?? this.artists,
      interestedUsersCount: interestedUsersCount ?? this.interestedUsersCount,
    );
  }
}
