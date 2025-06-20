import 'package:flutter/material.dart';
import 'view_workoutplan_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'generate_workout_plan.dart';
import 'customize_plan_page.dart'; // <-- Add this import

class AllWorkoutPlansPage extends StatefulWidget {
  final int userId;
  const AllWorkoutPlansPage({required this.userId});

  @override
  State<AllWorkoutPlansPage> createState() => _AllWorkoutPlansPageState();
}

class _AllWorkoutPlansPageState extends State<AllWorkoutPlansPage> {
  List<dynamic> plans = [];

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    String formattedUserId = 'U${widget.userId.toString().padLeft(3, '0')}';

    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/get-plans/$formattedUserId'),
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        plans = decoded['plans'];
      });
    } else {
      print('❌ Failed to fetch plans: ${response.statusCode}');
    }
  }

  String formatTimestamp(String timestamp) {
    try {
      DateTime dt = DateTime.parse(timestamp);
      return DateFormat('EEEE, MMMM d, y • h:mm a').format(dt);
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Workout Plans'),
      ),
      body: plans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No workout plans available.", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GenerateWorkoutPlanPage()),
                      );
                    },
                    icon: Icon(Icons.add),
                    label: Text("Generate New Plan"),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return ListTile(
                  leading: Icon(Icons.fitness_center),
                  title: Text('Workout Plan #${plan['plan_id']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration: ${plan['duration_months']} months'),
                      if (plan['created_at'] != null)
                        Text('Created on: ${formatTimestamp(plan['created_at'])}'),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewWorkoutPlanPage(planId: plan['plan_id']),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomizePlanPage(userId: widget.userId),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: "Create Custom Plan",
      ),
    );
  }
}
