import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseSelectorPage extends StatefulWidget {
  final int? workoutId; // Optional: used when editing existing plan
  final int? currentExerciseId;

  const ExerciseSelectorPage({this.workoutId, this.currentExerciseId});

  @override
  _ExerciseSelectorPageState createState() => _ExerciseSelectorPageState();
}

class _ExerciseSelectorPageState extends State<ExerciseSelectorPage> {
  List<dynamic> exercises = [];
  int page = 1;
  final int perPage = 10;
  bool isLoading = false;
  bool hasMore = true;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchExercises();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isLoading && hasMore) {
        page++;
        fetchExercises();
      }
    });
  }

  Future<void> fetchExercises() async {
    setState(() => isLoading = true);

    final response = await http.get(Uri.parse(
        'http://10.0.2.2:5000/exercise-library?page=$page&per_page=$perPage'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['exercises'];
      setState(() {
        exercises.addAll(data);
        if (data.length < perPage) hasMore = false;
      });
    } else {
      print('❌ Failed to load exercises: ${response.body}');
    }

    setState(() => isLoading = false);
  }

  Future<void> updateExercise(int workoutId, int newExerciseId) async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/update-exercise-plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'workout_id': workoutId,
        'new_exercise_id': newExerciseId,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Exercise updated');
    } else {
      print('❌ Failed to update exercise');
    }
  }

  Widget buildExerciseCard(dynamic ex) {
    final isSelected = ex['Exercise_ID'] == widget.currentExerciseId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(ex['name'] ?? 'No Name'),
        subtitle: Text('Level: ${ex['level']}, Category: ${ex['category']}'),
        trailing: isSelected ? Icon(Icons.check_circle, color: Colors.green) : null,
        onTap: () async {
          if (widget.workoutId != null) {
            // Edit mode
            await updateExercise(widget.workoutId!, ex['Exercise_ID']);
            Navigator.pop(context, true);
          } else {
            // Select mode (for customized plan)
            Navigator.pop(context, ex);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Exercise')),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: exercises.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < exercises.length) {
            return buildExerciseCard(exercises[index]);
          } else {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
        },
      ),
    );
  }
}
