import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'view_workoutplan_page.dart';
import 'diet_preference_page.dart';

class AllPlansPage extends StatefulWidget {
  final int userId;

  const AllPlansPage({super.key, required this.userId});

  @override
  State<AllPlansPage> createState() => _AllPlansPageState();
}

class _AllPlansPageState extends State<AllPlansPage> {
  List<dynamic> workoutPlans = [];
  List<Map<String, dynamic>> dietPlans = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchAllPlans();
  }

  Future<void> _fetchAllPlans() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      String formattedUserId = 'U${widget.userId.toString().padLeft(3, '0')}';

      final workoutResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/get-plans/$formattedUserId'),
      );

      final dietResponse = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/user-diet-plans/${widget.userId}'),
      );

      if (workoutResponse.statusCode == 200 && dietResponse.statusCode == 200) {
        final workoutData = json.decode(workoutResponse.body);
        final dietData = json.decode(dietResponse.body);

        setState(() {
          workoutPlans = workoutData['plans'] ?? [];
          dietPlans = List<Map<String, dynamic>>.from(dietData['diet_plans'] ?? []);
        });
      } else {
        setState(() {
          error = 'Failed to load some plans';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildWorkoutPlanItem(Map<String, dynamic> plan) {
    return Card(
      child: ListTile(
        title: Text("Workout Plan #${plan['plan_id']}"),
        subtitle: Text("Duration: ${plan['duration_months']} month(s)"),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewWorkoutPlanPage(planId: plan['plan_id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDietPlanItem(Map<String, dynamic> plan) {
    return Card(
      child: ListTile(
        title: Text(plan['title'] ?? 'Diet Plan'),
        subtitle: Text("Calories: ${plan['calories']} kcal"),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DietPreferencePage(userId: widget.userId.toString()),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Plans")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text("Workout Plans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (workoutPlans.isEmpty)
                      const Text("No workout plans found.")
                    else
                      ...workoutPlans.map((plan) => _buildWorkoutPlanItem(plan)).toList(),

                    const SizedBox(height: 24),
                    const Text("Diet Plans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (dietPlans.isEmpty)
                      const Text("No diet plans found.")
                    else
                      ...dietPlans.map((plan) => _buildDietPlanItem(plan)).toList(),
                  ],
                ),
    );
  }
}
