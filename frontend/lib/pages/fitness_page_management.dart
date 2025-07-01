import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'edit_fitness_page.dart';
import 'exercise_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FitnessPageManagementPage extends StatefulWidget {
  @override
  _FitnessPageManagementPageState createState() => _FitnessPageManagementPageState();
}

class _FitnessPageManagementPageState extends State<FitnessPageManagementPage> {
  List<dynamic> _exercises = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _searchQuery.isNotEmpty) return;

    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchExercises(page: _currentPage + 1);
    }
  }

  Future<void> _fetchExercises({int page = 1}) async {
    setState(() => _isLoading = true);

    final uri = Uri.http('10.0.2.2:5000', '/exercises', {
      'page': '$page',
      'per_page': '10',
    });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final exercises = data['exercises'];

        setState(() {
          if (page == 1) _exercises.clear();
          _exercises.addAll(exercises);
          _hasMore = exercises.length == 10;
          _currentPage = page;
        });
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExercise(int id) async {
    final response = await http.delete(Uri.parse('http://10.0.2.2:5000/delete-exercise/$id'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Exercise deleted")));
      _fetchExercises();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed")));
    }
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete Exercise"),
        content: Text("Are you sure you want to delete this exercise?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExercise(id);
            },
            child: Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

Future<void> _searchExercises(String query) async {
    if (query.isEmpty) {
      _searchQuery = '';
      _exercises.clear();
      _fetchExercises();
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
          _hasMore = false;
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

  void _navigateToEditPage(dynamic exMap) {
    final exercise = Exercise(
      id: exMap['Exercise_ID'],
      name: exMap['name'] ?? '',
      level: exMap['level'] ?? '',
      mechanic: exMap['mechanic'] ?? '',
      equipment: exMap['equipment'] ?? '',
      primaryMuscles: exMap['primaryMuscles'] is String
      ? List<String>.from(jsonDecode(exMap['primaryMuscles']))
      : List<String>.from(exMap['primaryMuscles'] ?? []),
      category: exMap['category'] ?? '',
      instructions: List<String>.from(exMap['instructions'] ?? []),
      imageUrls: List<String>.from(exMap['image_urls'] ?? []),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrEditExercisePage(exercise: exercise),
      ),
    ).then((_) => _fetchExercises());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToAddPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddOrEditExercisePage(),
      ),
    ).then((_) => _fetchExercises());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Exercises')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddPage(),
        child: Icon(Icons.add),
        tooltip: 'Add New Exercise',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search exercises',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: _searchExercises,
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _searchExercises(_searchController.text),
                      child: Text('Search'),
                    ),
                  ],
            ),
          ),
          Expanded(
            child: _exercises.isEmpty && _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _exercises.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final ex = _exercises[index];

                      return Card(
                        margin: EdgeInsets.all(10),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex['name'] ?? 'No Name',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('Level: ${ex['level'] ?? 'N/A'}'),
                              Text('Category: ${ex['category'] ?? 'N/A'}'),
                              Text('Mechanic: ${ex['mechanic'] ?? 'N/A'}'),
                              Text('Primary Muscles: ${ex['primaryMuscles'] ?? 'N/A'}'),
                              Text('Equipment: ${ex['equipment'] ?? 'N/A'}'),
                              SizedBox(height: 8),
                              if (ex['image_urls'] != null && ex['image_urls'].isNotEmpty)
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: (ex['image_urls'] as List<dynamic>).map((url) {
                                      return Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: CachedNetworkImage(
                                          imageUrl: 'http://10.0.2.2:5000$url',
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                          errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 100),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              else
                                Text("No image available"),
                              SizedBox(height: 8),
                              Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...((ex['instructions'] as List<dynamic>?)?.map((step) {
                                final cleaned = step.toString().replaceAll(RegExp(r'[\[\]"]'), '').trim();
                                return Text('• $cleaned');
                              }) ?? [Text("No instructions available")]),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    label: Text("Edit"),
                                    onPressed: () => _navigateToEditPage(ex),
                                  ),
                                  SizedBox(width: 10),
                                  TextButton.icon(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    label: Text("Delete"),
                                    onPressed: () => _showDeleteDialog(ex['Exercise_ID']),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
