import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'view_workoutplan_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GenerateWorkoutPlanPage extends StatefulWidget {
  @override
  _GenerateWorkoutPlanPageState createState() => _GenerateWorkoutPlanPageState();
}

class _GenerateWorkoutPlanPageState extends State<GenerateWorkoutPlanPage> {
  String? selectedLevel;
  String? selectedMechanic;
  String? selectedEquipment;
  String? selectedMuscle;
  String? selectedCategory;
  double durationMonths = 3;

  final levels = ['beginner', 'intermediate', 'expert'];
  final mechanics = ['null', 'isolation', 'compound'];
  final equipmentList = [
    "null", "medicine ball", "dumbbell", "body only", "bands", "kettlebells",
    "foam roll", "cable", "machine", "barbell", "exercise ball", "e-z curl bar", "other"
  ];
  final muscles = [
    "abdominals", "abductors", "adductors", "biceps", "calves", "chest",
    "forearms", "glutes", "hamstrings", "lats", "lower back", "middle back",
    "neck", "quadriceps", "shoulders", "traps", "triceps"
  ];
  final categories = [
    "powerlifting", "strength", "stretching", "cardio",
    "olympic weightlifting", "strongman", "plyometrics"
  ];

  Future<void> _generatePlan() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  
  if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID not found. Please log in again.")),
      );
      return;
  }
  final preferences = {
    'user_id': userId,
    'level': selectedLevel,
    'mechanic': selectedMechanic,
    'equipment': selectedEquipment,
    'primaryMuscles': selectedMuscle,
    'category': selectedCategory,
    'duration': durationMonths.toInt(),
  };

  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/generate-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(preferences),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final planId = json['plan_id']; // 👈 Make sure you extract this 

      if (planId == null) {
        print("No plan ID available");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to retrieve plan ID.")),
        );
        return;
      }

      // Show success dialog before redirecting
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Success"),
          content: Text("Workout plan generated successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewWorkoutPlanPage(
                      planId: json['plan_id'],
                    ),
                  ),
                );
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate plan.")),
      );
    }
  } catch (e) {
    print("Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred: $e")),
    );
  }
}

  Widget _buildDropdown(String label, List<String> options, String? selectedValue, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: selectedValue,
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generate Workout Plan")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDropdown("Level", levels, selectedLevel, (val) => setState(() => selectedLevel = val)),
            _buildDropdown("Mechanic", mechanics, selectedMechanic, (val) => setState(() => selectedMechanic = val)),
            _buildDropdown("Equipment", equipmentList, selectedEquipment, (val) => setState(() => selectedEquipment = val)),
            _buildDropdown("Primary Muscle", muscles, selectedMuscle, (val) => setState(() => selectedMuscle = val)),
            _buildDropdown("Category", categories, selectedCategory, (val) => setState(() => selectedCategory = val)),
            SizedBox(height: 20),
            Text("Plan Duration (Months): ${durationMonths.toInt()}"),
            Slider(
              min: 1,
              max: 12,
              divisions: 11,
              value: durationMonths,
              onChanged: (val) => setState(() => durationMonths = val),
              label: "${durationMonths.toInt()} months",
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generatePlan,
              child: Text("Generate Plan"),
            ),
          ],
        ),
      ),
    );
  }
}
