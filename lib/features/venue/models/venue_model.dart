class Venue {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> residentArtists;
  final List<String> ownedBy;
  final List<String> genres;
  final String location;

  Venue({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.residentArtists,
    required this.ownedBy,
    required this.genres,
    required this.location,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      description: json['description'] as String? ?? '',
      residentArtists: (json['residentArtists'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      ownedBy: (json['ownedBy'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      location: json['location'] as String? ?? '',
    );
  }
}
