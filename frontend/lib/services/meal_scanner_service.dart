import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class MealScanResult {
  final String mealScanId;
  final String foodName;
  final List<String> alternatives;
  final int calories;
  final Map<String, dynamic> nutrients;
  final bool success;
  final String? error;

  MealScanResult({
    required this.mealScanId,
    required this.foodName,
    required this.alternatives,
    required this.calories,
    required this.nutrients,
    required this.success,
    this.error,
  });

  factory MealScanResult.fromJson(Map<String, dynamic> json) {
    return MealScanResult(
      mealScanId: json['meal_scan_id'] ?? '',
      foodName: json['food_name'] ?? '',
      alternatives: List<String>.from(json['alternatives'] ?? []),
      calories: json['calories'] ?? 0,
      nutrients: json['nutrients'] ?? {},
      success: json['success'] ?? false,
      error: json['error'],
    );
  }
}

class MealScanHistory {
  final String mealScanId;
  final String userId;
  final String imagePath;
  final String foodName;
  final int calories;
  final Map<String, dynamic> nutrients;
  final DateTime timestamp;

  MealScanHistory({
    required this.mealScanId,
    required this.userId,
    required this.imagePath,
    required this.foodName,
    required this.calories,
    required this.nutrients,
    required this.timestamp,
  });

  factory MealScanHistory.fromJson(Map<String, dynamic> json) {
    return MealScanHistory(
      mealScanId: json['meal_scan_id'],
      userId: json['user_id'],
      imagePath: json['image_path'],
      foodName: json['food_name'],
      calories: (json['calories'] as num).toInt(),
      nutrients: json['nutrients'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class MealScannerService {
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // for Android emulator
  final http.Client _client = http.Client();

  // Scan meal from image
  Future<MealScanResult> scanMeal(File imageFile, String userId) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/meal-scan'),
      );

      request.fields['user_id'] = userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return MealScanResult.fromJson(json.decode(response.body));
      } else {
        return MealScanResult(
          mealScanId: '',
          foodName: '',
          alternatives: [],
          calories: 0,
          nutrients: {},
          success: false,
          error: 'Failed to scan meal: ${response.statusCode}',
        );
      }
    } catch (e) {
      return MealScanResult(
        mealScanId: '',
        foodName: '',
        alternatives: [],
        calories: 0,
        nutrients: {},
        success: false,
        error: 'Error: $e',
      );
    }
  }

  // Get user's meal scan history
  Future<List<MealScanHistory>> getMealHistory(String userId, {int limit = 50}) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/meal-scans/$userId?limit=$limit'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        List<dynamic> scans = data['meal_scans'];
        return scans.map((item) => MealScanHistory.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load meal history');
      }
    } catch (e) {
      throw Exception('Error loading meal history: $e');
    }
  }

  // Update meal scan
  Future<bool> updateMealScan(String mealScanId, {String? foodName, int? calories}) async {
    try {
      final response = await _client.put(
        Uri.parse('$baseUrl/meal-scan/$mealScanId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          if (foodName != null) 'food_name': foodName,
          if (calories != null) 'calories': calories,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
