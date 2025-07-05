import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoadingWorkout = true;
  bool _isLoadingExercise = false;
  Map<String, dynamic>? workoutAnalytics;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _exercises = [];
  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  bool isLoadingEngagement = true;
  Map<String, dynamic> engagementData = {};
  String errorMessage = '';

  bool isLoadingDietary = true;
  Map<String, dynamic> dietaryAnalytics = {};
  String dietaryError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchWorkoutAnalytics();
    fetchExercises(isInitial: true);
    fetchEngagementData();
    fetchDietaryAnalytics();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        fetchExercises();
      }
    });
  }

Future<void> logReportGeneration() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getInt('user_id').toString();

  if (userId == null) {
    print('User ID not found in SharedPreferences.');
    return;
  }

  final response = await http.post(
    Uri.parse('http://10.0.2.2:5000/api/log-report'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'user_id': userId}),
  );

  if (response.statusCode == 200) {
    print('Report logged successfully.');
  } else {
    print('Failed to log report: ${response.statusCode}');
  }
}


  Future<void> fetchWorkoutAnalytics() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/workout-analytics/global'));
    if (response.statusCode == 200) {
      setState(() {
        workoutAnalytics = json.decode(response.body);
        isLoadingWorkout = false;
      });
    } else {
      setState(() => isLoadingWorkout = false);
    }
  }

  Future<void> fetchExercises({bool isInitial = false}) async {
    if (_isLoadingExercise || !_hasMore) return;
    setState(() => _isLoadingExercise = true);

    if (isInitial) {
      _currentPage = 1;
      _exercises.clear();
      _hasMore = true;
    }

    final url = Uri.parse('http://10.0.2.2:5000/exercises?page=$_currentPage&per_page=$_perPage');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> newExercises = data['exercises'];
      setState(() {
        _exercises.addAll(newExercises);
        _isLoadingExercise = false;
        _currentPage++;
        if (newExercises.length < _perPage) _hasMore = false;
      });
    } else {
      setState(() => _isLoadingExercise = false);
    }
  }

  Future<void> fetchEngagementData() async {
    setState(() {
      isLoadingEngagement = true;
      errorMessage = '';
    });

    final uri = Uri.parse('http://10.0.2.2:5000/api/analytics/user_engagement');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        setState(() {
          engagementData = data;
          isLoadingEngagement = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoadingEngagement = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error: $e';
        isLoadingEngagement = false;
      });
    }
  }

  Future<void> fetchDietaryAnalytics() async {
    setState(() {
      isLoadingDietary = true;
      dietaryError = '';
    });

    final uri = Uri.parse('http://10.0.2.2:5000/api/admin/dietary-analytics?period_days=30');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true) {
          setState(() {
            dietaryAnalytics = jsonData['data'];
            isLoadingDietary = false;
          });
        } else {
          setState(() {
            dietaryError = jsonData['error'] ?? 'Unknown error occurred';
            isLoadingDietary = false;
          });
        }
      } else {
        setState(() {
          dietaryError = 'Error: ${response.statusCode}';
          isLoadingDietary = false;
        });
      }
    } catch (e) {
      setState(() {
        dietaryError = 'Network error: $e';
        isLoadingDietary = false;
      });
    }
  }

  Future<void> generateFullReport({
    required Map<String, dynamic> workoutAnalytics,
    required List<dynamic> exercises,
    required Map<String, dynamic> engagementData,
    required Map<String, dynamic> dietaryAnalytics,
  }) async {
    final pdf = pw.Document();
    final now = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    final completed = workoutAnalytics['completed_exercises'] ?? 0;
    final overdue = workoutAnalytics['overdue_exercises'] ?? 0;
    final totalTracked = completed + overdue;
    final totalExercises = exercises.length;

    final topUsers = engagementData['top_users_by_logins'] ?? [];
    final hourlyTrends = engagementData['hourly_trends'] ?? [];
    final dailyTrends = engagementData['daily_trends'] ?? [];

    pdf.addPage(pw.MultiPage(
      build: (context) => [
        pw.Text('Admin Analytics Report', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold)),
        pw.Text('Generated on $now', style: pw.TextStyle(fontSize: 12)),
        pw.SizedBox(height: 20),

        pw.Text('Workout Analytics', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Completed Exercises: $completed'),
        pw.Text('Overdue Exercises: $overdue'),
        pw.Text('Total Tracked Exercises: $totalTracked'),
        pw.Text('Total Available Exercises: $totalExercises'),
        pw.SizedBox(height: 20),

        pw.Text('User Engagement Analytics', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Total Logins: ${engagementData['overall_logins']}'),
        pw.Text('Total Logouts: ${engagementData['overall_logouts']}'),
        pw.Text('Unique Users Overall: ${engagementData['unique_users_overall']}'),
        pw.SizedBox(height: 10),
        pw.Text('Top 5 Users by Logins:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...topUsers.map<pw.Widget>((user) => pw.Text('User ID: ${user['user_id']} - ${user['login_count']} logins')),

        pw.SizedBox(height: 10),
        pw.Text('Hourly Login/Logout Trends:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...hourlyTrends.map<pw.Widget>((t) => pw.Text('${t['hour']}: ${t['logins']} logins | ${t['logouts']} logouts')),

        pw.SizedBox(height: 10),
        pw.Text('Daily Login/Logout Trends:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...dailyTrends.map<pw.Widget>((t) {
          final date = DateFormat('MMM dd').format(DateTime.parse(t['date']));
          return pw.Text('$date: ${t['logins']} logins | ${t['logouts']} logouts');
        }),

        pw.SizedBox(height: 20),
        pw.Text('Dietary Analytics', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Total Users: ${dietaryAnalytics['total_users']}'),
        pw.Text('Users with Diet Plans: ${dietaryAnalytics['users_with_diet_plans']}'),
        pw.SizedBox(height: 10),
        pw.Text('Average Daily Calories Per User:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...((dietaryAnalytics['average_daily_calories_per_user'] ?? {}) as Map<String, dynamic>).entries.map(
          (e) => pw.Text('${e.key}: ${e.value.toStringAsFixed(2)} kcal'),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Top 10 Logged Meals:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...((dietaryAnalytics['top_logged_meals'] ?? []) as List).map(
          (item) => pw.Text('${item['meal_name']}: ${item['count']} times'),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Top 10 Scanned Foods:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ...((dietaryAnalytics['top_scanned_foods'] ?? []) as List).map(
          (item) => pw.Text('${item['food_name']}: ${item['count']} times'),
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    await logReportGeneration();
  }

  Widget buildWorkoutTab() {
    final completed = (workoutAnalytics?['completed_exercises'] ?? 0);
    final overdue = (workoutAnalytics?['overdue_exercises'] ?? 0);
    final total = completed + overdue;

    return isLoadingWorkout
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Workout Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Completed: $completed'),
                    LinearProgressIndicator(value: total == 0 ? 0 : completed / total),
                    const SizedBox(height: 8),
                    Text('Overdue: $overdue'),
                    LinearProgressIndicator(value: total == 0 ? 0 : overdue / total, color: Colors.red),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _exercises.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _exercises.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                    }
                    final exercise = _exercises[index];
                    return ListTile(
                      title: Text(exercise['name'] ?? 'Unknown'),
                      subtitle: Text('Level: ${exercise['level'] ?? '-'}, Equipment: ${exercise['equipment'] ?? '-'}'),
                    );
                  },
                ),
              ),
            ],
          );
  }

  Widget buildEngagementTab() {
    return isLoadingEngagement
        ? const Center(child: CircularProgressIndicator())
        : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text('User Engagement Overview', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text('Total Logins: ${engagementData['overall_logins'] ?? 0}'),
                  Text('Total Logouts: ${engagementData['overall_logouts'] ?? 0}'),
                  Text('Unique Users: ${engagementData['unique_users_overall'] ?? 0}'),
                  const Divider(),
                  Text('Top 5 Users by Logins:', style: Theme.of(context).textTheme.bodyLarge),
                  ...((engagementData['top_users_by_logins'] ?? []) as List).map<Widget>((user) {
                    return ListTile(
                      leading: CircleAvatar(child: Text(user['user_id'].toString())),
                      title: Text('User ID: ${user['user_id']}'),
                      trailing: Text('${user['login_count']} logins'),
                    );
                  }).toList(),
                ],
              );
  }

  Widget buildDietaryTab() {
    if (isLoadingDietary) return const Center(child: CircularProgressIndicator());
    if (dietaryError.isNotEmpty) {
      return Center(child: Text(dietaryError, style: const TextStyle(color: Colors.red)));
    }
    if (dietaryAnalytics.isEmpty) {
      return const Center(child: Text('No dietary analytics data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Dietary Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Total Users: ${dietaryAnalytics['total_users']}'),
        Text('Users with Diet Plans: ${dietaryAnalytics['users_with_diet_plans']}'),
        const Divider(),
        const Text('Top Logged Meals:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...((dietaryAnalytics['top_logged_meals'] ?? []) as List).map((meal) =>
          ListTile(
            title: Text(meal['meal_name'] ?? 'N/A'),
            trailing: Text('Count: ${meal['count'] ?? 0}'),
          )),
        const Divider(),
        const Text('Top Scanned Foods:', style: TextStyle(fontWeight: FontWeight.bold)),
        ...((dietaryAnalytics['top_scanned_foods'] ?? []) as List).map((food) =>
          ListTile(
            title: Text(food['food_name'] ?? 'N/A'),
            trailing: Text('Count: ${food['count'] ?? 0}'),
          )),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Analytics Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Workout Analytics'),
            Tab(icon: Icon(Icons.people), text: 'User Engagement'),
            Tab(icon: Icon(Icons.restaurant), text: 'Dietary Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => generateFullReport(
              workoutAnalytics: workoutAnalytics!,
              exercises: _exercises,
              engagementData: engagementData,
              dietaryAnalytics: dietaryAnalytics,
            ),
            tooltip: 'Generate Full Report',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildWorkoutTab(),
          buildEngagementTab(),
          buildDietaryTab(),
        ],
      ),
    );
  }
}
