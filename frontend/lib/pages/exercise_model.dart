import "dart:convert";

class Exercise {
  final int id;
  final String name;
  final String level;
  final String mechanic;
  final String equipment;
  final List<String> primaryMuscles; // ✅ Changed from String to List<String>
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
  List<String> parseList(dynamic val) {
    if (val == null) return [];
    if (val is String) {
      try {
        return List<String>.from(jsonDecode(val));
      } catch (_) {
        return val.split(',').map((e) => e.trim()).toList();
      }
    }
    if (val is List) return List<String>.from(val);
    return [];
  }

  return Exercise(
    id: json['Exercise_ID'] ?? json['id'],
    name: json['name'] ?? '',
    level: json['level'] ?? '',
    mechanic: json['mechanic'] ?? '',
    equipment: json['equipment'] ?? '',
    primaryMuscles: parseList(json['primaryMuscles']), // ✅ fixed here
    category: json['category'] ?? '',
    instructions: parseList(json['instructions']),
    imageUrls: parseList(json['image_urls']),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'primaryMuscles': primaryMuscles, // ✅ send as list
      'category': category,
      'instructions': instructions,
      'image_urls': imageUrls,
    };
  }
}
