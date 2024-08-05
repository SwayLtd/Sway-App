// artist_model.dart

class Artist {
  final String id;
  final String name;
  final String imageUrl;
  final String description;
  final List<String> genres; // IDs of genres
  final List<String> upcomingEvents;
  final List<String> similarArtists;
  final Map<String, String> links;
  final int followers;
  final bool isFollowing;

  Artist({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.genres,
    required this.upcomingEvents,
    required this.similarArtists,
    required this.links,
    required this.followers,
    required this.isFollowing,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      genres: (json['genres'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      upcomingEvents: (json['upcomingEvents'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      similarArtists: (json['similarArtists'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      links: (json['links'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as String)) ??
          {},
      followers: json['followers'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }
}
