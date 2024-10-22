// lib/features/venue/models/venue_model.dart

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
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'location': location,
    };
  }

  Venue copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    String? location,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}
