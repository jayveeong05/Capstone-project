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
  late Future<List<dynamic>> _dietPlansFuture;

  @override
  void initState() {
    super.initState();
    _dietPlansFuture = fetchDietPlans();
  }

  Future<List<dynamic>> fetchDietPlans() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/diet-plans/${widget.userId}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['diet_plans'] ?? [];
    } else {
      throw Exception('Failed to load diet plans');
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
      setState(() {
        _dietPlansFuture = fetchDietPlans();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Diet Plan')),
      body: FutureBuilder<List<dynamic>>(
        future: _dietPlansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final plans = snapshot.data!;
          if (plans.isEmpty) {
            return Center(
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
            );
          }

          // Show latest plan
          final plan = plans.first;
          return ListTile(
            title: Text(plan['plan_name'] ?? 'Diet Plan'),
            subtitle: Text('Calories: ${plan['daily_calories']} | Days: ${plan['duration_days']}'),
            onTap: () => _openDietPlanDetails(plan['diet_plan_id']),
          );
        },
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(plan['diet_plan']['plan_name'] ?? '', style: Theme.of(context).textTheme.titleLarge),
              Text('Calories: ${plan['diet_plan']['daily_calories']}'),
              const SizedBox(height: 16),
              ...mealPlan.entries.map((entry) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ExpansionTile(
                    title: Text(entry.key),
                    children: (entry.value as List).map<Widget>((meal) {
                      final recipe = meal['recipe'];
                      return ListTile(
                        title: Text('${meal['meal_type']}: ${recipe['title']}'),
                        subtitle: Text('Calories: ${recipe['calories']}'),
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

class GenerateDietPlanPage extends StatefulWidget {
  final String userId;
  const GenerateDietPlanPage({required this.userId, super.key});

  @override
  State<GenerateDietPlanPage> createState() => _GenerateDietPlanPageState();
}

class _GenerateDietPlanPageState extends State<GenerateDietPlanPage> {
  final _formKey = GlobalKey<FormState>();
  int _durationDays = 7;
  String _planName = 'My Diet Plan';
  bool _loading = false;
  String? _error;

  Future<void> _generatePlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/generate-diet-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'duration_days': _durationDays,
          'plan_name': _planName,
        }),
      );
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _error = data['error'] ?? 'Failed to generate plan';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Diet Plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _planName,
                decoration: const InputDecoration(labelText: 'Plan Name'),
                onChanged: (v) => _planName = v,
              ),
              TextFormField(
                initialValue: '7',
                decoration: const InputDecoration(labelText: 'Duration (days)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _durationDays = int.tryParse(v) ?? 7,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : _generatePlan,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Generate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}