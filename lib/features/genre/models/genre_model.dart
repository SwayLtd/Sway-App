class Genre {
  final String id;
  final String name;
  final String description;
  final String bpmRange;

  Genre({
    required this.id,
    required this.name,
    required this.description,
    required this.bpmRange,
  });

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'].toString(), // Conversion explicite en String
      name: json['name'] as String,
      description: json['description'] as String,
      bpmRange: json['bpm_range'].toString(), // Conversion explicite en String
    );
  }
}
