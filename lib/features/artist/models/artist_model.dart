// lib/features/artist/models/artist_model.dart

class Artist {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final List<int> genres; // IDs of genres
  final List<int>? upcomingEvents; // Make non-nullable
  final List<int>? similarArtists;
  final Map<String, String>? links;
  final int? followers; // Make optional
  final bool? isFollowing; // Make optional

  Artist({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.genres,
    this.upcomingEvents = const [], // Default to empty list
    this.similarArtists,
    this.links,
    this.followers, // Optional
    this.isFollowing, // Optional
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as int?,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      description: json['description'] as String? ?? '',
      genres: [], // Initialize as empty; handle via separate service
      upcomingEvents: null,
      similarArtists: null,
      links: null,
      followers: null, // Initialize as null
      isFollowing: null, // Initialize as null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
    };
  }

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
    );
  }
}
