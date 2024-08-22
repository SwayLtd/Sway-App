// artist_model.dart

class Artist {
  final int id;
  final String name;
  final String imageUrl;
  final String description;
  final List genres; // IDs of genres
  final List upcomingEvents;
  final List similarArtists;
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
      id: json['id'],
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String? ?? '',
      genres: (json['genres'])
              ?.map((e) => e)
              .toList() ??
          [],
      upcomingEvents: (json['upcomingEvents'])
              ?.map((e) => e)
              .toList() ??
          [],
      similarArtists: (json['similarArtists'])
              ?.map((e) => e)
              .toList() ??
          [],
      links: (json['links'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, value as String)) ??
          {},
      followers: json['followers'] ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'genres': genres,
      'upcomingEvents': upcomingEvents,
      'similarArtists': similarArtists,
      'links': links,
      'followers': followers,
      'isFollowing': isFollowing,
    };
  }
}
