import 'package:flutter/material.dart';
import 'view_workoutplan_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'generate_workout_plan.dart';

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
  // Format the userId to match "U" + 3-digit format (e.g., U006)
  String formattedUserId = 'U${widget.userId.toString().padLeft(3, '0')}';

  final response = await http.get(
    Uri.parse('http://10.0.2.2:5000/get-plans/$formattedUserId'),
  );

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    print(decoded); // ✅ Debugging output
    setState(() {
      plans = decoded['plans'];
    });
  } else {
    print('❌ Failed to fetch plans: ${response.statusCode}');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
 body: plans.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No workout plans available.",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>GenerateWorkoutPlanPage() )
                  );// Replace with actual route if needed
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
            title: Text('Workout Plan #${plan['id']}'),
            subtitle: Text('Duration: ${plan['duration_months']} months'),
            trailing: Icon(Icons.arrow_forward),
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
    );
  }
}
