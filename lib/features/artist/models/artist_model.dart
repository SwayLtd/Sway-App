// Updated Artist model in lib/features/artist/models/artist_model.dart

class Artist {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final List<int> genres;
  final List<int>? upcomingEvents;
  final List<int>? similarArtists;
  final Map<String, String>? links;
  final int? followers;
  final bool? isFollowing;
  final bool isVerified; // New property to indicate verification status

  Artist({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.genres,
    this.upcomingEvents = const [],
    this.similarArtists,
    this.links,
    this.followers,
    this.isFollowing,
    this.isVerified = false,
  });

  // Factory constructor to create an Artist instance from JSON data
  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int?,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String? ?? '',
      genres: List<int>.from(json['genres'] ?? []),
      upcomingEvents:
          (json['upcoming_events'] as List<dynamic>?)?.cast<int>() ?? [],
      similarArtists: (json['similar_artists'] as List<dynamic>?)?.cast<int>(),
      links: (json['links'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)),
      followers: json['followers'] as int?,
      isFollowing: json['is_following'] as bool?,
      isVerified: json['is_verified'] as bool? ??
          false, // Extract the verification status
    );
  }

  // Converts the Artist instance to JSON data
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'is_verified': isVerified, // Include the verification status
    };
  }

  // Allows copying the Artist instance with optional new values
  Artist copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    List<int>? genres,
    List<int>? upcomingEvents,
    List<int>? similarArtists,
    Map<String, String>? links,
    int? followers,
    bool? isFollowing,
    bool? isVerified,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      genres: genres ?? this.genres,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      similarArtists: similarArtists ?? this.similarArtists,
      links: links ?? this.links,
      followers: followers ?? this.followers,
      isFollowing: isFollowing ?? this.isFollowing,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
