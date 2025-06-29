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
      calories: json['calories'] is double ? json['calories'].toInt() : json['calories'] ?? 0,
      nutrients: json['nutrients'] ?? {},
      success: json['success'] ?? false,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    // Note: alternatives are intentionally NOT included here as they are not saved to DB
    return {
      'meal_scan_id': mealScanId,
      'food_name': foodName,
      'calories': calories,
      'nutrients': nutrients,
      'success': success,
      'error': error,
      // 'alternatives': alternatives, // OMITTED from toJson as they are not sent to DB
    };
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

  Future<MealScanResult> updateMealScanWithFoodName(String mealScanId, String newFoodName) async {
    try {
      print('DEBUG (MealScannerService): Sending PUT request to $baseUrl/meal-scan/$mealScanId');
      final requestBody = json.encode({
        'food_name': newFoodName,
      });
      print('DEBUG (MealScannerService): Request Body: $requestBody');

      final response = await _client.put(
        Uri.parse('$baseUrl/meal-scan/$mealScanId'),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('DEBUG (MealScannerService): Response Status Code: ${response.statusCode}');
      print('DEBUG (MealScannerService): Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        // Extract top-level success flag
        final bool success = responseBody['success'] ?? false;
        
        // Extract data payload
        final Map<String, dynamic> data = responseBody['data'] ?? {};

        // Determine error message for failure cases
        String? errorMessage;
        if (!success) { // If top-level success is false
          if (responseBody.containsKey('error') && responseBody['error'] != null) {
            errorMessage = responseBody['error'].toString();
          } else if (responseBody.containsKey('message') && responseBody['message'] != null) {
            errorMessage = responseBody['message'].toString();
          } else {
            errorMessage = 'Backend reported failure (status 200, success: false) with no specific error message.';
          }
        }

        // Manually construct MealScanResult using data from both top-level and 'data' field
        return MealScanResult(
          mealScanId: data['meal_scan_id'] ?? mealScanId, // Use data's ID if present, else fallback
          foodName: data['food_name'] ?? newFoodName,     // Use data's food name, else fallback
          alternatives: List<String>.from(data['alternatives'] ?? []),
          // Safely convert calories from data, handling int/double
          calories: data['calories'] is double ? data['calories'].toInt() : data['calories'] ?? 0,
          nutrients: data['nutrients'] ?? {},
          success: success, // Use the actual top-level success flag
          error: errorMessage, // Only populate error message if success is false
        );
      } else {
        // Handle non-200 status codes as definite failures
        String errorMessage = 'Server error ${response.statusCode}: ${response.body}';
        return MealScanResult(
          mealScanId: mealScanId, // Fallback
          foodName: newFoodName, // Fallback
          alternatives: [],
          calories: 0,
          nutrients: {},
          success: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      print('DEBUG (MealScannerService): Caught network or parsing error: $e');
      return MealScanResult(
        mealScanId: mealScanId, // Fallback
        foodName: newFoodName, // Fallback
        alternatives: [],
        calories: 0,
        nutrients: {},
        success: false,
        error: 'Network or parsing exception: $e',
      );
    }
  }


  Future<bool> deleteMealScan(String mealScanId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$baseUrl/meal-scan/$mealScanId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Failed to delete meal scan: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting meal scan: $e');
      return false;
    }
  }
}
