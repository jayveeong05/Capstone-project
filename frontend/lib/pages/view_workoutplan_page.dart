import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

import 'exercise_selector_page.dart';

class ViewWorkoutPlanPage extends StatefulWidget {
  final int planId;

  const ViewWorkoutPlanPage({required this.planId});

  @override
  State<ViewWorkoutPlanPage> createState() => _ViewWorkoutPlanPageState();
}

class _ViewWorkoutPlanPageState extends State<ViewWorkoutPlanPage> {
  List<String> dates = [];
  String? selectedDate;
  List<dynamic> exercises = [];

  @override
  void initState() {
    super.initState();
    fetchDates();
  }

  Future<void> fetchDates() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/get-plan-dates/${widget.planId}'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        dates = List<String>.from(data['dates']);
        selectedDate = dates.isNotEmpty ? dates[0] : null;
      });
      if (selectedDate != null) fetchExercisesByDate(selectedDate!);
    } else {
      print("❌ Failed to load dates: ${response.statusCode}");
    }
  }

  Future<void> fetchExercisesByDate(String dateStr) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/get-plan-date/${widget.planId}/$dateStr'),
    );
    if (response.statusCode == 200) {
      setState(() {
        exercises = json.decode(response.body)['exercises'];
      });
    } else {
      print("❌ Error fetching exercises: ${response.statusCode}");
    }
  }

  Future<void> deleteWorkout(int workoutId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/delete-exercise-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'workout_id': workoutId}),
    );

    if (response.statusCode == 200) {
      print('✅ Deleted successfully');
      fetchExercisesByDate(selectedDate!);
    } else {
      print('❌ Failed to delete: ${response.body}');
    }
  }

  String formatDate(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget buildExerciseCard(dynamic ex) {
    final imageUrls = (ex['image_urls'] as List<dynamic>).take(3).toList();
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ex['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Level: ${ex['level']}'),
            Text('Category: ${ex['category']}'),
            Text('Equipment: ${ex['equipment']}'),
            const SizedBox(height: 8),
            if (imageUrls.isNotEmpty)
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: CachedNetworkImage(
                        imageUrl: 'http://10.0.2.2:5000$url',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.broken_image),
                      ),
                    );
                  },
                ),
              )
            else
              const Text("No image available"),
            const SizedBox(height: 8),
            const Text('Instructions:'),
            ...((ex['instructions'] as List<dynamic>).map((step) => Text('• $step'))),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: const Text("Edit"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseSelectorPage(
                          workoutId: ex['Workout_id'],
                          currentExerciseId: ex['Exercise_ID'],
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text("Delete"),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text("Are you sure you want to delete this workout?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await deleteWorkout(ex['Workout_id']);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Plan')),
      body: Column(
        children: [
          if (dates.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButton<String>(
                value: selectedDate,
                isExpanded: true,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedDate = value);
                    fetchExercisesByDate(value);
                  }
                },
                items: dates
                    .map((dateStr) => DropdownMenuItem(
                          value: dateStr,
                          child: Text(formatDate(dateStr)),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text("No exercises found."))
                : ListView.builder(
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = exercises[index];
                      return buildExerciseCard(exercise);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
