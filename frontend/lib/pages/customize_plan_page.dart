import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'generate_workout_plan.dart';
class CustomizePlanPage extends StatefulWidget {
  final int userId;
  const CustomizePlanPage({required this.userId});

  @override
  State<CustomizePlanPage> createState() => _CustomizePlanPageState();
}

class _CustomizePlanPageState extends State<CustomizePlanPage> {
  List<dynamic> exerciseLibrary = [];
  Set<int> selectedExerciseIds = {};
  DateTime? selectedStartDate;
  double durationMonths = 3;
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final response = await http.get(Uri.parse(
        'http://10.0.2.2:5000/exercise-library?page=$currentPage&per_page=10'));

    if (response.statusCode == 200) {
      final List<dynamic> newExercises = json.decode(response.body)['exercises'];
      setState(() {
        exerciseLibrary.addAll(newExercises);
        currentPage++;
        isLoading = false;
        if (newExercises.length < 10) hasMore = false;
      });
    } else {
      print("❌ Failed to load exercises");
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Pick start date";
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _pickStartDate() async {
    DateTime now = DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedStartDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => selectedStartDate = picked);
    }
  }

  Future<void> _savePlan() async {
    if (selectedStartDate == null || selectedExerciseIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a start date and at least one exercise")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/save-custom-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 'U${widget.userId.toString().padLeft(3, '0')}',
        'duration': durationMonths.toInt(),
        'start_date': DateFormat('yyyy-MM-dd').format(selectedStartDate!),
        'exercise_ids': selectedExerciseIds.toList(),
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      print("❌ Failed to save plan: ${response.body}");
    }
  }

  Widget buildExerciseTile(dynamic exercise) {
    final isSelected = selectedExerciseIds.contains(exercise['Exercise_ID']);
    return ListTile(
      title: Text(exercise['name'] ?? 'Unnamed'),
      subtitle: Text("Level: ${exercise['level']} | Equipment: ${exercise['equipment']}"),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? Colors.green : Colors.grey,
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedExerciseIds.remove(exercise['Exercise_ID']);
          } else {
            selectedExerciseIds.add(exercise['Exercise_ID']);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Customize Workout Plan")),
      body: Column(
        children: [
          ListTile(
            title: Text("Start Date: ${formatDate(selectedStartDate)}"),
            trailing: Icon(Icons.calendar_today),
            onTap: _pickStartDate,
          ),
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
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.auto_fix_high),
                label: Text("Auto Generate Plan"),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GenerateWorkoutPlanPage(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Save Custom Plan"),
                onPressed: _savePlan,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  fetchExercises();
                }
                return false;
              },
              child: ListView.builder(
                itemCount: exerciseLibrary.length,
                itemBuilder: (context, index) => buildExerciseTile(exerciseLibrary[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
