class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final bool isFollowing;
  final List<String> genres;
  final List<String> upcomingEvents;
  final List<String> similarArtists;
  final Map<String, String> links;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.isFollowing,
    required this.genres,
    required this.upcomingEvents,
    required this.similarArtists,
    required this.links,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      isFollowing: json['isFollowing'] as bool,
      genres: (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      upcomingEvents: (json['upcomingEvents'] as List<dynamic>).map((e) => e as String).toList(),
      similarArtists: (json['similarArtists'] as List<dynamic>).map((e) => e as String).toList(),
      links: Map<String, String>.from(json['links'] as Map<String, dynamic>? ?? {}),
    );
  }
}
