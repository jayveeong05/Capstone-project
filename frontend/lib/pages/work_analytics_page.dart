import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GlobalDashboard extends StatefulWidget {
  @override
  _GlobalDashboardState createState() => _GlobalDashboardState();
}

class _GlobalDashboardState extends State<GlobalDashboard> {
  bool isLoading = true;
  bool _isLoading = false;
  Map<String, dynamic>? analytics;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _exercises = [];

  int _currentPage = 1;
  final int _perPage = 10;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
    _fetchExercises(isInitial: true);

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchExercises();
      }
    });
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

  Future<void> _fetchExercises({bool isInitial = false}) async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

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
        _isLoading = false;
        _currentPage++;
        if (newExercises.length < _perPage) _hasMore = false;
      });
    } else {
      setState(() => _isLoading = false);
      print("Failed to fetch exercises");
    }
  }

  Future<void> _searchExercises(String query) async {
    if (query.isEmpty) {
      _searchQuery = '';
      _fetchExercises(isInitial: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    final url = Uri.parse('http://10.0.2.2:5000/search?q=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _exercises = data['exercises'];
          _hasMore = false; // disable lazy loading on search
        });
      } else {
        print("Search failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error during search: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

 Future<void> _generateReport() async {
  final pdf = pw.Document();

  final completed = (analytics?['completed_exercises'] ?? 0);
  final overdue = (analytics?['overdue_exercises'] ?? 0);
  final total = completed + overdue;

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('Exercise Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 20),

        pw.Text('📊 Workout Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Text('Completed Exercises: $completed'),
        pw.Text('Overdue Exercises: $overdue'),
        pw.Text('Total Tracked Exercises: $total'),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
  );
}

  Widget _buildBarChart() {
  final completed = (analytics?['completed_exercises'] ?? 0);
  final overdue = (analytics?['overdue_exercises'] ?? 0);
  final total = completed + overdue;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Workout Summary', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Text('Completed: $completed'),
      LinearProgressIndicator(
        value: total == 0 ? 0 : completed / total,
        color: Colors.green,
        backgroundColor: Colors.grey[300],
      ),
      SizedBox(height: 16),
      Text('Overdue: $overdue'),
      LinearProgressIndicator(
        value: total == 0 ? 0 : overdue / total,
        color: Colors.red,
        backgroundColor: Colors.grey[300],
      ),
    ],
  );
}

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exercise Report Generator'),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _exercises.isEmpty ? null : _generateReport,
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: _buildBarChart(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () => _searchExercises(_searchController.text.trim()),
                      ),
                    ),
                    onSubmitted: (value) => _searchExercises(value.trim()),
                  ),
                ),
                if (_isLoading) CircularProgressIndicator(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _exercises.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return Center(child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ));
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
            ),
    );
  }
}
