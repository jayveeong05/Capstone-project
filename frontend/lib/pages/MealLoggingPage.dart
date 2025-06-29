// In MealLoggingPage.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MealLoggingPage extends StatefulWidget {
  // --- NEW: Add mealToEdit as an optional parameter ---
  final Map<String, dynamic>? mealToEdit;

  const MealLoggingPage({super.key, this.mealToEdit});

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
  bool _isEditing = false; // --- NEW: Flag to indicate edit mode ---
  String? _mealId; // --- NEW: To store meal_id when editing ---

  @override
  void initState() {
    super.initState();
    // --- NEW: Initialize form fields if in edit mode ---
    if (widget.mealToEdit != null) {
      _isEditing = true;
      _mealId = widget.mealToEdit!['meal_id'];
      _mealType = widget.mealToEdit!['meal_type'] ?? 'Breakfast';
      _mealNameController.text = widget.mealToEdit!['meal_name'] ?? '';
      _caloriesController.text = widget.mealToEdit!['calories']?.toString() ?? '';
      _notesController.text = widget.mealToEdit!['notes'] ?? '';
    }
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<String?> _getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic userIdRaw = prefs.get('user_id'); // Get the value as dynamic
    if (userIdRaw != null) {
      return userIdRaw.toString(); // Convert the dynamic value to a String
    }
    return null; // Return null if the key 'user_id' is not found
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
      setState(() { _isSubmitting = false; });
      return;
    }

    final mealData = {
      'user_id': userId,
      'meal_type': _mealType,
      'meal_name': _mealNameController.text,
      'calories': int.parse(_caloriesController.text),
      'notes': _notesController.text,
    };

    http.Response response;
    String successMessage;
    String errorMessage;

    // --- NEW: Conditional logic for POST (new meal) or PUT (edit meal) ---
    if (_isEditing) {
      // IMPORTANT: Replace 'http://localhost:5000' with your actual Flask backend URL
      response = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/logged-meal/$_mealId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mealData),
      );
      successMessage = 'Meal updated successfully!';
      errorMessage = 'Failed to update meal.';
    } else {
      // IMPORTANT: Replace 'http://localhost:5000' with your actual Flask backend URL
      response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/log-meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(mealData),
      );
      successMessage = 'Meal logged successfully!';
      errorMessage = 'Failed to log meal.';
    }

    if (response.statusCode == 200) { // Backend returns 200 for both success/fail in its JSON
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
        // --- NEW: Pop with 'true' to signal history page to reload ---
        Navigator.pop(context, true); // Go back to previous page (history)
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$errorMessage: ${data['error']}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$errorMessage Server returned ${response.statusCode}')),
      );
    }

    setState(() {
      _isSubmitting = false;
    });
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
        fetchCaloriesForMeal(selection);
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

  Future<void> fetchCaloriesForMeal(String mealTitle) async {
    final uri = Uri.parse(
      'http://10.0.2.2:5000/api/recipe-details?title=${Uri.encodeComponent(mealTitle)}',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Ensure 'calories' key exists and is an int/num
      final int? calories = data['calories'];
      if (calories != null) {
        setState(() {
          _caloriesController.text = calories.toString();
        });
      } else {
        // If no calories found for the meal, clear the field or set to 0
        setState(() {
          _caloriesController.text = ''; // Or '0' if you prefer
        });
        print('💡 No specific calorie found for "$mealTitle".');
      }
    } else {
      print('❌ Failed to fetch calories for "$mealTitle": ${response.statusCode} - ${response.body}');
      // You might want to clear the calories field on error
      setState(() {
        _caloriesController.text = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // --- NEW: Dynamic AppBar title ---
        title: Text(_isEditing ? 'Edit Meal Log' : 'Log New Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _mealType,
                decoration: const InputDecoration(
                  labelText: 'Meal Type',
                  border: OutlineInputBorder(),
                ),
                items: <String>['Breakfast', 'Lunch', 'Dinner', 'Snack']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _mealType = newValue!;
                  });
                },
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
                    // --- NEW: Dynamic button text ---
                    : Text(_isEditing ? 'Update Meal' : 'Log Meal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}