// lib/features/venue/models/venue_model.dart

class Venue {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final String location;
  final bool isVerified; // New property to indicate verification status

  Venue({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.location,
    this.isVerified = false,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ??
          false, // Extract the verification status
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'location': location,
      'is_verified': isVerified, // Include the verification status
    };
  }

  Venue copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    String? location,
    bool? isVerified,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
