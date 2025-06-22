import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DietPreferencePage extends StatefulWidget {
  final String userId;
  const DietPreferencePage({required this.userId, super.key});

  @override
  State<DietPreferencePage> createState() => _DietPreferencePageState();
}

class _DietPreferencePageState extends State<DietPreferencePage> {
  final _formKey = GlobalKey<FormState>();

  String _dietType = 'None';
  String _dietaryGoal = 'Weight Loss';
  String _allergies = '';
  bool _loading = false;
  String? _error;

  final List<String> dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'High Protein',
    'Low Carb',
  ];

  final List<String> goals = [
    'Weight Loss',
    'Muscle Gain',
    'Maintenance',
  ];

  Future<void> _showPreviewDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Your Preferences'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Diet Type: $_dietType'),
              Text('Dietary Goal: $_dietaryGoal'),
              Text('Allergies: ${_allergies.isEmpty ? 'None' : _allergies}'),
              const SizedBox(height: 10),
              const Text(
                'Do you want to save and generate your diet plan?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _finalSubmit(); // Call final API submission
              },
            ),
          ],
        );
      },
    );
  }

  void _submitPreferences() {
    if (_formKey.currentState!.validate()) {
      _showPreviewDialog(); // Show preview first
    }
  }

  Future<void> _finalSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Update preferences
      final prefsResponse = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/update-diet-preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'diet_type': _dietType,
          'dietary_goal': _dietaryGoal,
          'allergies': _allergies,
        }),
      );

      if (prefsResponse.statusCode != 200) {
        final data = jsonDecode(prefsResponse.body);
        setState(() {
          _error = data['error'] ?? 'Failed to update preferences';
        });
        return;
      }

      // Generate diet plan (replaces current ongoing if exists)
      final generateResponse = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/generate-diet-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'duration_days': 7,
          'plan_name': 'My Personalized Diet Plan',
        }),
      );


      if (generateResponse.statusCode == 201) {
        Navigator.pop(context, true); // success
      } else {
        final data = jsonDecode(generateResponse.body);
        setState(() {
          _error = data['error'] ?? 'Failed to generate plan';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Diet Type'),
                value: _dietType,
                items: dietTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) => setState(() => _dietType = val!),
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dietary Goal'),
                value: _dietaryGoal,
                items: goals.map((goal) {
                  return DropdownMenuItem(value: goal, child: Text(goal));
                }).toList(),
                onChanged: (val) => setState(() => _dietaryGoal = val!),
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Allergies (comma-separated)',
                ),
                onChanged: (val) => _allergies = val,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loading ? null : _submitPreferences,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Save & Generate Plan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
