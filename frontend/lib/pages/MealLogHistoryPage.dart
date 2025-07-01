import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    _checkAndShowMealReminder();
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

  void _showMealReminderDialog(String title, String content, {bool isError = false}) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: isError ? Colors.red : Colors.blueAccent)),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndShowMealReminder() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdInt = prefs.getInt('user_id');
    if (userIdInt == null) {
      // No user ID, can't check reminder. Error already handled by _loadMealLogs or other parts.
      return;
    }
    final userId = 'U${userIdInt.toString().padLeft(3, '0')}';
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String apiUrl = 'http://10.0.2.2:5000/api/user-progress/$userId/$today';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      String title = 'Daily Meal Reminder';
      String message;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['success']) {
          final int mealsCompleted = data['progress']['meals_completed'];
          if (mealsCompleted < 3) {
            message = 'You\'ve logged $mealsCompleted meals today. Aim for at least 3!';
          } else {
            message = 'Great job! You\'ve logged $mealsCompleted meals today. Keep it up!';
          }
        } else {
          if (data['message'] == 'No progress found for this date.') {
             message = 'No meals logged today. Don\'t forget to log your meals!';
          } else {
             message = 'Failed to get your meal progress: ${data['error'] ?? data['message']}';
             title = 'Meal Reminder Error';
          }
        }
      } else {
        message = 'Server error (${response.statusCode}) while checking meal progress.';
        title = 'Meal Reminder Error';
      }
      _showMealReminderDialog(title, message, isError: title.contains('Error'));
    } catch (e) {
      _showMealReminderDialog(
        'Meal Reminder Error',
        'Could not connect to the server to check meal progress. Please check your internet connection.',
        isError: true,
      );
      print('Error checking meal reminder: $e');
    }
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
      _checkAndShowMealReminder();
    }
  }

  Map<String, dynamic> _calculateDailySummary(List<dynamic> mealsForDate) {
    int totalCalories = 0;
    int mealsCompleted = mealsForDate.length;

    for (var meal in mealsForDate) {
      totalCalories += (meal['calories'] as num? ?? 0).toInt();
    }
    return {'totalCalories': totalCalories, 'mealsCompleted': mealsCompleted};
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Log History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : mealLogsByDate.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No meal logs yet.\nLog a meal to see it here!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  children: mealLogsByDate.keys.map((date) {
                    final mealsForDate = mealLogsByDate[date]!;
                    final dailySummary = _calculateDailySummary(mealsForDate);
                    final totalCalories = dailySummary['totalCalories'];
                    final mealsCompleted = dailySummary['mealsCompleted'];
                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.blue.withOpacity(0.05),
                          highlightColor: Colors.blue.withOpacity(0.03),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Meals: $mealsCompleted | Total Kcal: $totalCalories',
                              style: const TextStyle(fontSize: 14, color: Colors.black54),
                            ),
                          ),
                          trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                          children: mealsForDate.map((meal) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2),
                              child: Dismissible(
                                key: Key(meal['meal_id']),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) => _deleteMeal(meal['meal_id']),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[50],
                                    child: Icon(_getMealIcon(meal['meal_type']), color: Colors.blue[700]),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        meal['meal_name'] ?? 'N/A',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 8),
                                      if (meal['meal_type'] != null)
                                        Chip(
                                          label: Text(
                                            meal['meal_type'][0].toUpperCase() + meal['meal_type'].substring(1),
                                            style: const TextStyle(fontSize: 12, color: Colors.white),
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                  subtitle: Text.rich(
                                    TextSpan(
                                      children: [
                                        const WidgetSpan(
                                          child: Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                                        ),
                                        TextSpan(
                                          text: '  ${meal['calories']} kcal',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (meal['notes'] != null && meal['notes'].toString().isNotEmpty)
                                        IconButton(
                                          icon: const Icon(Icons.notes, color: Colors.grey),
                                          tooltip: 'View Notes',
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
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        tooltip: 'Edit Meal',
                                        onPressed: () => _navigateToEditMeal(meal),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    if (meal['notes'] != null && meal['notes'].toString().isNotEmpty) {
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
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewMealLog,
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Meal'),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}