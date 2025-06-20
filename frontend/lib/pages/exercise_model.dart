class Exercise {
  final int id;
  final String name;
  final String level;
  final String mechanic;
  final String equipment;
  final String primaryMuscles;
  final String category;
  final List<String> instructions;
  final List<String> imageUrls;

  Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.mechanic,
    required this.equipment,
    required this.primaryMuscles,
    required this.category,
    required this.instructions,
    required this.imageUrls,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'] ?? '',
      level: json['level'] ?? '',
      mechanic: json['mechanic'] ?? '',
      equipment: json['equipment'] ?? '',
      primaryMuscles: json['primaryMuscles'] ?? '',
      category: json['category'] ?? '',
      instructions: List<String>.from(json['instructions'] ?? []),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
    );
  }
}