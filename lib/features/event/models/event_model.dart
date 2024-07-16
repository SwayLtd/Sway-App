class Event {
  final String id;
  final String title;
  final String dateTime;
  final String venue;
  final String description;
  final String imageUrl;
  final String distance;
  final String price;
  final List<String> organizers;
  final List<String> genres;
  final List<String> artists;

  Event({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.venue,
    required this.description,
    required this.imageUrl,
    required this.distance,
    required this.price,
    required this.organizers,
    required this.genres,
    required this.artists,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      dateTime: json['dateTime'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      price: json['price'] as String? ?? '',
      organizers: (json['organizers'] as List<dynamic>?)?.map((e) => e as String? ?? '').toList() ?? [],
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String? ?? '').toList() ?? [],
      artists: (json['artists'] as List<dynamic>?)?.map((e) => e as String? ?? '').toList() ?? [],
    );
  }
}
