import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ViewWorkoutPlanPage extends StatefulWidget {
  final int planId;
  ViewWorkoutPlanPage({required this.planId});

  @override
  _ViewWorkoutPlanPageState createState() => _ViewWorkoutPlanPageState();
}

class _ViewWorkoutPlanPageState extends State<ViewWorkoutPlanPage> {
  List<String> weeks = []; // E.g., ['Week 1', 'Week 2']
  String? selectedWeek;
  List<dynamic> exercises = [];

  @override
  void initState() {
    super.initState();
    fetchWeeks();
  }

  Future<void> fetchWeeks() async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:5000/get-plan/${widget.planId}')); // Create this endpoint
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        weeks = List<String>.from(data['weeks']);
        selectedWeek = weeks.isNotEmpty ? weeks[0] : null;
      });
      if (selectedWeek != null) fetchExercisesByWeek(selectedWeek!);
    } else {
      print("❌ Failed to load weeks: ${response.statusCode}");
    }
  }

  Future<void> fetchExercisesByWeek(String week) async {
    final response = await http.get(Uri.parse(
        'http://10.0.2.2:5000/get-plan-week/${widget.planId}/$week'));
    if (response.statusCode == 200) {
      setState(() {
        exercises = json.decode(response.body)['exercises'];
      });
    } else {
      print("❌ Error fetching exercises: ${response.statusCode}");
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
            ex['name'] ?? 'No Name',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Level: ${ex['level'] ?? 'N/A'}'),
          Text('Category: ${ex['category'] ?? 'N/A'}'),
          Text('Equipment: ${ex['equipment'] ?? 'N/A'}'),
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
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 100);
                      },
                    ),
                  );
                }).toList(),
              ),
            )
          else
            const Text("No image available"),
          const SizedBox(height: 8),
          const Text('Instructions:'),
          ...((ex['instructions'] as List<dynamic>?)?.map((step) => Text('• $step')) ?? [const Text("No instructions available")]),
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
          if (weeks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: DropdownButton<String>(
                value: selectedWeek,
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedWeek = value);
                    fetchExercisesByWeek(value);
                  }
                },
                items: weeks
                    .map((week) => DropdownMenuItem(
                          value: week,
                          child: Text(week),
                        ))
                    .toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) =>
                  buildExerciseCard(exercises[index]),
            ),
          ),
        ],
      ),
    );
  }
}
