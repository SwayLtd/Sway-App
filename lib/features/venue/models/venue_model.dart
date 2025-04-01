// lib/features/venue/models/venue_model.dart

class Venue {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final String location;
  final bool isVerified;
  // Champs pour les coordonnées du lieu
  final double? latitude;
  final double? longitude;

  Venue({
    this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
    required this.location,
    this.isVerified = false,
    this.latitude,
    this.longitude,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id']
          as int?, // dans getVenueByEventId, l'ID sera renvoyé sous 'id'
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      latitude: json['venue_latitude'] != null
          ? (json['venue_latitude'] as num).toDouble()
          : null,
      longitude: json['venue_longitude'] != null
          ? (json['venue_longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'location': location,
      'is_verified': isVerified,
      'venue_latitude': latitude,
      'venue_longitude': longitude,
    };
  }

  Venue copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? description,
    String? location,
    bool? isVerified,
    double? latitude,
    double? longitude,
  }) {
    return Venue(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
