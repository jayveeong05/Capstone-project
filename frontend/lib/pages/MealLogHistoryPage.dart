// In MealLogHistoryPage.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'MealLoggingPage.dart'; // Ensure this import is correct

class MealLogHistoryPage extends StatefulWidget {
  const MealLogHistoryPage({super.key});

  @override
  State<MealLogHistoryPage> createState() => _MealLogHistoryPageState();
}

class _MealLogHistoryPageState extends State<MealLogHistoryPage> {
  Map<String, List<dynamic>> mealLogsByDate = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMealLogs();
  }

  // --- Utility function to get meal icon (existing) ---
  IconData _getMealIcon(String? mealType) {
    switch (mealType?.toLowerCase()) {
      case 'breakfast':
        return Icons.breakfast_dining;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.food_bank;
    }
  }

  // --- Existing _loadMealLogs function ---
  Future<void> _loadMealLogs() async {
    setState(() {
      isLoading = true; // Set loading to true when data is being fetched
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final dynamic rawUserId = prefs.get('user_id');
    final String userId = rawUserId?.toString() ?? '';
    if (userId.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:5000/api/logged-meals/$userId'), 
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        setState(() {
          mealLogsByDate = Map<String, List<dynamic>>.from(data['logged_meals']);
        });
      } else {
        // Handle error from API (e.g., show a snackbar)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meal logs: ${data['error']}')),
        );
        mealLogsByDate = {}; // Clear previous data on error
      }
    } else {
      // Handle HTTP error (e.g., server down, network issue)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${response.statusCode}: Could not connect to API.')),
      );
      mealLogsByDate = {}; // Clear previous data on error
    }
    setState(() {
      isLoading = false; // Set loading to false once data is fetched or error occurs
    });
  }

  // Delete Meal function
  Future<bool?> _deleteMeal(String mealId) async {
    // Show confirmation dialog first
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this meal log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // User cancels, return false
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // User confirms, return true
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false; // If dialog dismissed by tapping outside, treat as cancel

    if (!confirmDelete) {
      // If user cancelled or dialog dismissed, prevent dismissal of the item
      return false;
    }

    // If user confirmed, proceed with API call
    final response = await http.delete(
      Uri.parse('http://10.0.2.2:5000/api/logged-meal/$mealId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal deleted successfully!')),
        );
        _loadMealLogs(); // Reload meals after successful deletion
        return true; // Allow the Dismissible widget to be dismissed
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete meal: ${data['error']}')),
        );
        _loadMealLogs(); // Reload to revert swipe effect if delete failed on API
        return false; // Prevent dismissal if API reported failure
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${response.statusCode}: Failed to delete meal.')),
      );
      _loadMealLogs(); // Reload to revert swipe effect if HTTP error occurred
      return false; // Prevent dismissal if HTTP request failed
    }
  }

  // --- NEW: _navigateToEditMeal function ---
  Future<void> _navigateToEditMeal(Map<String, dynamic> meal) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealLoggingPage(
          mealToEdit: meal, // Pass the meal data for editing
        ),
      ),
    );

    // If a meal was updated/logged on the editing page, reload history
    if (result == true) {
      _loadMealLogs();
    }
  }

  Future<void> _navigateToNewMealLog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MealLoggingPage(mealToEdit: null), // Pass null for a new meal
      ),
    );

    // If a new meal was successfully logged, reload the history page
    if (result == true) {
      _loadMealLogs();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Log History'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mealLogsByDate.isEmpty
              ? const Center(
                  child: Text('No meal logs yet. Log a meal to see it here!'),
                )
              : ListView(
                  children: mealLogsByDate.keys.map((date) {
                    final mealsForDate = mealLogsByDate[date]!;
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ExpansionTile(
                        title: Text(
                          date,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        // Optionally, add a summary for the day here
                        // trailing: Text('Total Kcal: ${calculateDailyTotal(mealsForDate)}'),
                        children: mealsForDate.map((meal) {
                          // --- WRAP ListTile with Dismissible for swipe-to-delete ---
                          return Dismissible(
                            key: Key(meal['meal_id']), // Unique key for Dismissible
                            direction: DismissDirection.endToStart, // Swipe from right to left
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) => _deleteMeal(meal['meal_id']), // Call delete function
                            onDismissed: (direction) {
                              // This is called AFTER confirmDismiss returns true and the item is dismissed from UI
                              // No need to do anything here as _deleteMeal already handles API call and reload
                            },
                            child: ListTile(
                              leading: Icon(_getMealIcon(meal['meal_type'])),
                              title: Text(meal['meal_name'] ?? 'N/A'),
                              subtitle: Text('${meal['calories']} kcal'),
                              trailing: Row( // Use a Row to place multiple icons
                                mainAxisSize: MainAxisSize.min, // Keep row compact
                                children: [
                                  if (meal['notes'] != null &&
                                      meal['notes'].toString().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.notes, color: Colors.grey),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Meal Notes'),
                                            content: Text(meal['notes']),
                                            actions: [
                                              TextButton(
                                                child: const Text('Close'),
                                                onPressed: () => Navigator.pop(context),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  // --- NEW: Edit Icon ---
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _navigateToEditMeal(meal),
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Original onTap for notes can remain or be removed if edit icon handles all.
                                // If notes icon is separate, onTap can be removed.
                                if (meal['notes'] != null &&
                                    meal['notes'].toString().isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Meal Notes'),
                                      content: Text(meal['notes']),
                                      actions: [
                                        TextButton(
                                          child: const Text('Close'),
                                          onPressed: () => Navigator.pop(context),
                                        )
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewMealLog, // Call the new navigation function
        tooltip: 'Log a new meal', // Optional tooltip for accessibility
        child: const Icon(Icons.add), // The plus icon
      ),
    );
  }
}