import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'exercise_selector_page.dart';

class ViewWorkoutPlanPage extends StatefulWidget {
  final int planId;
  ViewWorkoutPlanPage({required this.planId});

  @override
  _ViewWorkoutPlanPageState createState() => _ViewWorkoutPlanPageState();
}

class _ViewWorkoutPlanPageState extends State<ViewWorkoutPlanPage> {
  List<String> dates = []; // e.g., ['2025-06-21']
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
      final Map<String, dynamic> data = json.decode(response.body);
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
    // Optionally: refresh exercises list
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
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ex['name'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Level: ${ex['level']}'),
            Text('Category: ${ex['category']}'),
            Text('Equipment: ${ex['equipment']}'),
            const SizedBox(height: 8),
            if (ex['image_urls'] != null && ex['image_urls'].isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (ex['image_urls'] as List<dynamic>).map((url) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.network(
                        'http://10.0.2.2:5000$url',
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
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
                  icon: Icon(Icons.edit, color: Colors.blue),
                  label: Text("Edit"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ExerciseSelectorPage(
                          workoutId: ex['workout_id'],
                          currentExerciseId: ex['Exercise_ID'],
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text("Delete"),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Confirm Delete"),
                        content: Text("Are you sure you want to delete this workout?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
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
                child: ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseSelectorPage(
                              workoutId: exercise['Workout_id'],         // ✅ Use this
                              currentExerciseId: exercise['Exercise_ID'], // ✅ Current selected exercise
                            ),
                          ),
                        );
                      },
                      child: buildExerciseCard(exercise),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}
