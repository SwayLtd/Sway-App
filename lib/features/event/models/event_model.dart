class Event {
  final String id;
  final String title;
  final String dateTime;
  final String venue;
  final String description;
  final String imageUrl;
  final List<String> genres;
  final String distance;
  final String price;
  final List<String> organizers;
  final List<String> lineup;
  final int interested;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.venue,
    required this.description,
    required this.imageUrl,
    required this.genres,
    required this.distance,
    required this.price,
    required this.organizers,
    required this.lineup,
    required this.interested,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: json['dateTime'] as String,
      venue: json['venue'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      distance: json['distance'] as String,
      price: json['price'] as String,
      organizers: (json['organizers'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      lineup: (json['lineup'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      interested: json['interested'] as int? ?? 0,
    );
  }
}
