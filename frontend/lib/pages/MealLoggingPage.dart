import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealLoggingPage extends StatefulWidget {
  const MealLoggingPage({super.key});

  @override
  State<MealLoggingPage> createState() => _MealLoggingPageState();
}

class _MealLoggingPageState extends State<MealLoggingPage> {
  final _formKey = GlobalKey<FormState>();

  String _mealType = 'Breakfast';
  final TextEditingController _mealNameController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<void> _submitMeal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final userId = await _getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in.')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/logged-meal'), // Replace with your API
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'meal_type': _mealType,
        'meal_name': _mealNameController.text.trim(),
        'calories': double.tryParse(_caloriesController.text.trim()) ?? 0,
        'notes': _notesController.text.trim(),
      }),
    );

    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 201) {
      Navigator.pop(context); // Go back after success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal logged successfully.')),
      );
    } else {
      final error = json.decode(response.body)['error'] ?? 'Failed to log meal.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<List<String>> _fetchMealSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/meal-name-suggestions/$query'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> suggestions = json.decode(response.body);
      return suggestions.cast<String>();
    } else {
      return [];
    }
  }

  Widget _buildMealNameAutocomplete() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return await _fetchMealSuggestions(textEditingValue.text);
      },
      onSelected: (String selection) {
        _mealNameController.text = selection;
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        _mealNameController.text = controller.text;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: const InputDecoration(
            labelText: 'Meal Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'Enter meal name' : null,
        );
      },
    );
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Your Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _mealType,
                items: ['Breakfast', 'Lunch', 'Dinner']
                    .map((meal) => DropdownMenuItem(
                          value: meal,
                          child: Text(meal),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _mealType = value!),
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              _buildMealNameAutocomplete(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calories',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0) {
                    return 'Enter valid calorie amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMeal,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Log Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
