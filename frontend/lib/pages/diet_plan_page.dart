import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/diet_preference_page.dart';
import 'package:http/http.dart' as http;

class DietPlansPage extends StatefulWidget {
  final String userId;
  const DietPlansPage({required this.userId, super.key});

  @override
  State<DietPlansPage> createState() => _DietPlansPageState();
}

class _DietPlansPageState extends State<DietPlansPage> {
  List<Map<String, dynamic>> _plans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDietPlans();
  }

  Future<void> _fetchDietPlans() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/user-diet-plans/${widget.userId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _plans = List<Map<String, dynamic>>.from(data['diet_plans'] ?? []);
        });
      } else {
        setState(() {
          _error = 'Failed to load plans';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openDietPlanDetails(String dietPlanId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietPlanDetailPage(dietPlanId: dietPlanId),
      ),
    );
  }

  void _openGenerateDietPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DietPreferencePage(userId: widget.userId),
      ),
    );
    if (result == true) {
      _fetchDietPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePlan = _plans.firstWhere(
      (plan) => plan['status'] == 'Active' || plan['user_status'] == 'Active',
      orElse: () => <String, dynamic>{},
    );
    final archivedPlans = _plans
        .where((plan) =>
            (plan['status'] != 'Active' && plan['user_status'] != 'Active') &&
            plan['diet_plan_id'] != activePlan['diet_plan_id'])
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Diet Plan')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _plans.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No diet plan found.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _openGenerateDietPlan,
                            child: const Text('Generate Diet Plan'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchDietPlans,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Active Diet Plan',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (activePlan.isNotEmpty)
                            Card(
                              color: Colors.green[50],
                              child: ListTile(
                                title: Text(activePlan['plan_name'] ?? 'My Diet Plan'),
                                subtitle: Text(
                                    'Start: ${activePlan['start_date']} | End: ${activePlan['end_date']}'),
                                trailing: Chip(
                                  label: const Text('Active'),
                                  backgroundColor: Colors.green.withOpacity(0.2),
                                  labelStyle:
                                      const TextStyle(color: Colors.green),
                                ),
                                onTap: () => _openDietPlanDetails(
                                    activePlan['diet_plan_id']),
                              ),
                            )
                          else
                            const Text('No active diet plan.'),
                          const SizedBox(height: 24),
                          Text(
                            'Archived Plans',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (archivedPlans.isEmpty)
                            const Text('No archived plans.'),
                          ...archivedPlans.map((plan) {
                            final status =
                                plan['user_status'] ?? plan['status'] ?? 'Unknown';
                            final statusColor = {
                              'Finished': Colors.red,
                              'Replaced': Colors.grey,
                              'Cancelled': Colors.orange,
                            }[status] ??
                                Colors.blueGrey;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title:
                                    Text(plan['plan_name'] ?? 'My Diet Plan'),
                                subtitle: Text(
                                    'Start: ${plan['start_date']} | End: ${plan['end_date']}'),
                                trailing: Chip(
                                  label: Text(status),
                                  backgroundColor: statusColor.withOpacity(0.2),
                                  labelStyle:
                                      TextStyle(color: statusColor),
                                ),
                                onTap: () => _openDietPlanDetails(
                                    plan['diet_plan_id']),
                              ),
                            );
                          }).toList(),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _openGenerateDietPlan,
                            icon: const Icon(Icons.add),
                            label: const Text('Create New Plan'),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class DietPlanDetailPage extends StatelessWidget {
  final String dietPlanId;
  const DietPlanDetailPage({required this.dietPlanId, super.key});

  Future<Map<String, dynamic>> fetchDietPlanDetails() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/diet-plan/$dietPlanId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load diet plan details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Plan Details')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDietPlanDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plan = snapshot.data!;
          final mealPlan = plan['meal_plan'] as Map<String, dynamic>;
          final diet = plan['diet_plan'];

          final status = diet['user_status'] ?? diet['status'] ?? 'Unknown';
          final startDate = diet['start_date'] ?? 'N/A';
          final endDate = diet['end_date'] ?? 'N/A';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(diet['plan_name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Description: ${diet['description'] ?? 'No description'}', style: const TextStyle(color: Colors.blueGrey)),
              Text('Status: $status'),
              Text('Calories/day: ${diet['daily_calories']}'),
              Text('Protein: ${diet['protein_grams']}g | Carbs: ${diet['carbs_grams']}g | Fat: ${diet['fat_grams']}g | Fiber: ${diet['fiber_grams']}g'),
              Text('Duration: ${diet['duration_days']} days'),
              Text('Start Date: $startDate'),
              Text('End Date: $endDate'),
              const Divider(height: 24),
              ...mealPlan.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(entry.key),
                    children: (entry.value as List).map<Widget>((meal) {
                      final recipe = meal['recipe'];
                      return ListTile(
                        title: Text('${meal['meal_type']}: ${recipe['title']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Calories: ${recipe['calories']}'),
                            const SizedBox(height: 4),
                            Text('Ingredients: ${recipe['ingredients']}'),
                            const SizedBox(height: 2),
                            Text('Instructions: ${recipe['instructions']}', maxLines: 3, overflow: TextOverflow.ellipsis),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                child: const Text('View Full Recipe'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(recipe['title']),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Ingredients:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text(recipe['ingredients'] ?? 'N/A'),
                                              const SizedBox(height: 10),
                                              Text('Instructions:', style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text(recipe['instructions'] ?? 'N/A'),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Close'),
                                          )
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                        isThreeLine: true,
                      );
                    }).toList(),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
