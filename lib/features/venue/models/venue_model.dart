// lib/features/venue/models/venue_model.dart

class Venue {
  final int? id;
  final String name;
  final String imageUrl;
  final String description;
  final String location;
  final bool isVerified;
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
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isVerified: json['is_verified'] as bool? ?? false,
      // Si votre API retourne déjà latitude/longitude, sinon laisser null.
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
      'location': location,
      'is_verified': isVerified,
    };

    // Si les coordonnées sont présentes, on construit le point géographique en WKT
    if (latitude != null && longitude != null) {
      map['location_point'] = 'SRID=4326;POINT($longitude $latitude)';
    }

    return map;
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
