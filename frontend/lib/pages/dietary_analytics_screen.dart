// lib/pages/dietary_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For date formatting if needed

class DietaryAnalyticsScreen extends StatefulWidget {
  const DietaryAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _DietaryAnalyticsScreenState createState() => _DietaryAnalyticsScreenState();
}

class _DietaryAnalyticsScreenState extends State<DietaryAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String _errorMessage = '';

  // Use the same base URL as your other backend calls, for example:
  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; // IMPORTANT: Replace with your actual backend URL

  @override
  void initState() {
    super.initState();
    _fetchDietaryAnalytics();
  }

  Future<void> _fetchDietaryAnalytics({int periodDays = 30}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _analyticsData = {};
    });

    final String apiUrl = '$_backendBaseUrl/api/admin/dietary-analytics?period_days=$periodDays';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData['success'] == true) {
          setState(() {
            _analyticsData = decodedData['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = decodedData['error'] ?? 'Failed to fetch analytics due to an unknown reason.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to connect to the backend. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildAnalyticsContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)));
    }

    if (_analyticsData.isEmpty) {
      return const Center(child: Text('No analytics data available.', style: TextStyle(fontSize: 16)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('General Statistics'),
          _buildDataRow('Total Users', _analyticsData['total_users']?.toString() ?? 'N/A'),
          _buildDataRow('Users with Diet Plans', _analyticsData['users_with_diet_plans']?.toString() ?? 'N/A'),

          const SizedBox(height: 20),
          _buildSectionTitle('Average Daily Calories Per User (Last 30 Days)'),
          _buildMapList(_analyticsData['average_daily_calories_per_user'], (key, value) => '  $key: ${value?.toStringAsFixed(2) ?? 'N/A'} kcal'),

          const SizedBox(height: 20),
          _buildSectionTitle('Meal Type Distribution (Last 30 Days)'),
          _buildMapList(_analyticsData['meal_type_distribution'], (key, value) {
            final count = value['count'] ?? 0;
            final percentage = value['percentage'] ?? 0.0;
            return '  $key: $count (${percentage.toStringAsFixed(2)}%)';
          }),

          const SizedBox(height: 20),
          _buildSectionTitle('Top 10 Logged Meals (Last 30 Days)'),
          _buildList(_analyticsData['top_logged_meals'], (item) => '  ${item['meal_name']}: Count ${item['count']}'),

          const SizedBox(height: 20),
          _buildSectionTitle('Dietary Goal Distribution'),
          _buildMapList(_analyticsData['dietary_goal_distribution'], (key, value) {
            final count = value['count'] ?? 0;
            final percentage = value['percentage'] ?? 0.0;
            return '  $key: $count (${percentage.toStringAsFixed(2)}%)';
          }),

          const SizedBox(height: 20),
          _buildSectionTitle('Allergy Distribution'),
          _buildMapList(_analyticsData['allergy_distribution'], (key, value) => '  $key: $value'),

          const SizedBox(height: 20),
          _buildSectionTitle('Top 10 Scanned Foods (Last 30 Days)'),
          _buildList(_analyticsData['top_scanned_foods'], (item) => '  ${item['food_name']}: Count ${item['count']}'),

          const SizedBox(height: 20),
          _buildSectionTitle('Average BMI by Dietary Goal'),
          _buildMapList(_analyticsData['average_bmi_by_dietary_goal'], (key, value) {
            final avgBmi = value['average_bmi'] ?? 0.0;
            final userCount = value['user_count'] ?? 0;
            return '  $key: Avg BMI ${avgBmi.toStringAsFixed(2)} (Users: $userCount)';
          }),

          const SizedBox(height: 20),
          _buildSectionTitle('Calorie Adherence Over Time (Last 30 Days)'),
          _buildList(_analyticsData['calorie_adherence_over_time'], (item) {
            final date = item['date'] ?? 'N/A';
            final avgCalories = item['average_calories']?.toStringAsFixed(2) ?? 'N/A';
            final avgMeals = item['average_meals_completed']?.toStringAsFixed(2) ?? 'N/A';
            return '  $date: Avg Calories $avgCalories, Avg Meals $avgMeals';
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontSize: 15, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildMapList(Map<String, dynamic>? data, String Function(String key, dynamic value) formatter) {
    if (data == null || data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final key = data.keys.elementAt(index);
        final value = data[key];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Text(formatter(key, value), style: const TextStyle(fontSize: 15, color: Colors.black87)),
        );
      },
    );
  }

  Widget _buildList(List<dynamic>? data, String Function(dynamic item) formatter) {
    if (data == null || data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Text(formatter(item), style: const TextStyle(fontSize: 15, color: Colors.black87)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Habit Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _buildAnalyticsContent(),
    );
  }
}