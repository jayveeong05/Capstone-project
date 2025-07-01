import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';

class DietaryAnalyticsScreen extends StatefulWidget {
  const DietaryAnalyticsScreen({Key? key}) : super(key: key);

  @override
  _DietaryAnalyticsScreenState createState() => _DietaryAnalyticsScreenState();
}

class _DietaryAnalyticsScreenState extends State<DietaryAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String _errorMessage = '';

  static const String _backendBaseUrl = 'http://10.0.2.2:5000'; 

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

  // Add refresh action
  Future<void> _refreshAnalytics() async {
    await _fetchDietaryAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Habit Analytics'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshAnalytics,
          ),
        ],
      ),
      body: _buildAnalyticsContent(),
      backgroundColor: Colors.grey[100],
    );
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

    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('General Statistics'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatIcon(Icons.people, 'Total Users', _analyticsData['total_users']?.toString() ?? 'N/A'),
                    const SizedBox(width: 24),
                    _buildStatIcon(Icons.restaurant_menu, 'With Diet Plans', _analyticsData['users_with_diet_plans']?.toString() ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Average Daily Calories Per User (Last 30 Days)'),
                _buildMapList(_analyticsData['average_daily_calories_per_user'], (key, value) =>
                  ListTile(
                    leading: const Icon(Icons.local_fire_department, color: Colors.orange),
                    title: Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: Text('${value?.toStringAsFixed(2) ?? 'N/A'} kcal', style: const TextStyle(color: Colors.black87)),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Meal Type Distribution (Last 30 Days)'),
                _buildMapList(_analyticsData['meal_type_distribution'], (key, value) {
                  final count = value['count'] ?? 0;
                  final percentage = value['percentage'] ?? 0.0;
                  return ListTile(
                    leading: const Icon(Icons.fastfood, color: Colors.green),
                    title: Text(key),
                    trailing: Text('$count (${percentage.toStringAsFixed(2)}%)'),
                  );
                }),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Top 10 Logged Meals (Last 30 Days)'),
                _buildList(_analyticsData['top_logged_meals'], (item) =>
                  ListTile(
                    leading: const Icon(Icons.lunch_dining, color: Colors.blueAccent),
                    title: Text(item['meal_name'] ?? 'N/A'),
                    trailing: Text('Count ${item['count'] ?? ''}'),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Dietary Goal Distribution'),
                _buildMapList(_analyticsData['dietary_goal_distribution'], (key, value) {
                  final count = value['count'] ?? 0;
                  final percentage = value['percentage'] ?? 0.0;
                  return ListTile(
                    leading: const Icon(Icons.flag, color: Colors.purple),
                    title: Text(key),
                    trailing: Text('$count (${percentage.toStringAsFixed(2)}%)'),
                  );
                }),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Allergy Distribution'),
                _buildMapList(_analyticsData['allergy_distribution'], (key, value) =>
                  ListTile(
                    leading: const Icon(Icons.warning_amber, color: Colors.redAccent),
                    title: Text(key),
                    trailing: Text(value.toString()),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Top 10 Scanned Foods (Last 30 Days)'),
                _buildList(_analyticsData['top_scanned_foods'], (item) =>
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner, color: Colors.teal),
                    title: Text(item['food_name'] ?? 'N/A'),
                    trailing: Text('Count ${item['count'] ?? ''}'),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Average BMI by Dietary Goal'),
                _buildMapList(_analyticsData['average_bmi_by_dietary_goal'], (key, value) {
                  final avgBmi = value['average_bmi'] ?? 0.0;
                  final userCount = value['user_count'] ?? 0;
                  return ListTile(
                    leading: const Icon(Icons.monitor_weight, color: Colors.indigo),
                    title: Text(key),
                    subtitle: Text('Users: $userCount'),
                    trailing: Text('Avg BMI ${avgBmi.toStringAsFixed(2)}'),
                  );
                }),
              ],
            ),
          ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Calorie Adherence Over Time (Last 30 Days)'),
                _buildList(_analyticsData['calorie_adherence_over_time'], (item) {
                  final date = item['date'] ?? 'N/A';
                  final avgCalories = item['average_calories']?.toStringAsFixed(2) ?? 'N/A';
                  final avgMeals = item['average_meals_completed']?.toStringAsFixed(2) ?? 'N/A';
                  return ListTile(
                    leading: const Icon(Icons.timeline, color: Colors.deepOrange),
                    title: Text(date),
                    subtitle: Text('Avg Meals $avgMeals'),
                    trailing: Text('Avg Cal $avgCalories'),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blueAccent,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatIcon(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue[100],
            child: Icon(icon, color: Colors.blue[700]),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildMapList(Map<String, dynamic>? data, Widget Function(String key, dynamic value) builder) {
    if (data == null || data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    return Column(
      children: data.keys.map((key) => builder(key, data[key])).toList(),
    );
  }

  Widget _buildList(List<dynamic>? data, Widget Function(dynamic item) builder) {
    if (data == null || data.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.0),
        child: Text('No data available.', style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    return Column(
      children: data.map((item) => builder(item)).toList(),
    );
  }
}