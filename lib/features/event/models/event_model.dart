// event_model.dart

class Event {
  final int id;
  final String title;
  final String type;
  final String dateTime;
  final String endDateTime;
  final int venue;
  final String description;
  final String imageUrl;
  final String distance;
  final String price;
  final List promoters;
  final List genres;
  final List artists;

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
      id: json['id'],
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? '',
      dateTime: json['dateTime'] as String? ?? '',
      endDateTime: json['endDateTime'] as String? ?? '',
      venue: json['venue'] ?? 0,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      price: json['price'] as String? ?? '',
      promoters: (json['promoters'] as List?)?.map((e) => e).toList() ?? [],
      genres: (json['genres'] as List?)?.map((e) => e).toList() ?? [],
      artists: (json['artists'] as List?)?.map((e) => e).toList() ?? [],
    );
  }
}
