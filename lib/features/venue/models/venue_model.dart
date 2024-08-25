class Venue {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final String location;

  Venue({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.location,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }
}
