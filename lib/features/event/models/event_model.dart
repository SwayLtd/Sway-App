// lib/features/event/models/event_model.dart

class Event {
  final int id;
  final String title;
  final String type;
  final DateTime dateTime;
  final DateTime endDateTime;
  final int venue;
  final String description;
  final String imageUrl;
  final String distance;
  final String price;
  final List<int> promoters;
  final List<int> genres;
  final List<int> artists;

  Event({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    required this.endDateTime,
    required this.venue,
    required this.description,
    required this.imageUrl,
    required this.distance,
    required this.price,
    required this.promoters,
    required this.genres,
    required this.artists,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      dateTime: DateTime.parse(json['date_time'] as String),
      endDateTime: DateTime.parse(json['end_date_time'] as String),
      venue: json['venue'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      price: json['price'] as String? ?? '',
      promoters: (json['promoters'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      artists: (json['artists'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'date_time': dateTime.toIso8601String(),
      'end_date_time': endDateTime.toIso8601String(),
      'venue': venue,
      'description': description,
      'image_url': imageUrl,
      'distance': distance,
      'price': price,
      'promoters': promoters,
      'genres': genres,
      'artists': artists,
    };
  }
}
