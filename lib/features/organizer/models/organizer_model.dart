class Organizer {
  final String id;
  final String name;
  final String imageUrl;
  final int followers;
  final bool isFollowing;
  final String description;
  final List<String> upcomingEvents;

  Organizer({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.followers,
    required this.isFollowing,
    required this.description,
    required this.upcomingEvents,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) {
    return Organizer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      followers: json['followers'] as int? ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      upcomingEvents: (json['upcomingEvents'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}
