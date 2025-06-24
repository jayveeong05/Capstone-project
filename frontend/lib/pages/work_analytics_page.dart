import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class GlobalDashboard extends StatefulWidget {
  @override
  _GlobalDashboardState createState() => _GlobalDashboardState();
}

class _GlobalDashboardState extends State<GlobalDashboard> {
  bool isLoading = true;
  Map<String, dynamic>? analytics;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/workout-analytics/global'));

    if (response.statusCode == 200) {
      setState(() {
        analytics = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load analytics")),
      );
    }
  }

  Widget _buildBarChart() {
    final completed = (analytics?['completed_exercises'] ?? 0).toDouble();
    final overdue = (analytics?['overdue_exercises'] ?? 0).toDouble();

    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: completed, color: Colors.green)], showingTooltipIndicators: [0]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: overdue, color: Colors.red)], showingTooltipIndicators: [0]),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 0:
                    return Text("Completed");
                  case 1:
                    return Text("Overdue");
                  default:
                    return Text("");
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Global Workout Dashboard")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Users: ${analytics?['total_users']}", style: TextStyle(fontSize: 18)),
                  Text("Total Plans: ${analytics?['total_plans']}", style: TextStyle(fontSize: 18)),
                  Text("Average Progress: ${analytics?['average_progress_percent']}%", style: TextStyle(fontSize: 18)),
                  Text("Most Chosen Exercise: ${analytics?['most_chosen_exercise'] ?? 'N/A'}", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 24),
                  Text("Exercise Status Overview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 200, child: _buildBarChart()),
                ],
              ),
            ),
    );
  }
}
