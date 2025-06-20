import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';

class FitnessPage extends StatefulWidget {
  @override
  _FitnessPageState createState() => _FitnessPageState();
}

class _FitnessPageState extends State<FitnessPage> {
  List<dynamic> _exercises = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedLevel;
  String? _selectedMechanic;
  String? _selectedEquipment;
  String? _selectedPrimaryMuscle;
  String? _selectedCategory;

  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchExercises();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_hasMore || _isLoading || _searchQuery.isNotEmpty) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchExercises(page: _currentPage + 1);
    }
  }

  Future<void> _fetchExercises({int page = 1}) async {
    setState(() {
      _isLoading = true;
    });

    final uri = Uri.http('10.0.2.2:5000', '/exercises', {
      'page': '$page',
      'per_page': '10',
      if (_selectedLevel != null) 'level': _selectedLevel!,
      if (_selectedMechanic != null) 'mechanic': _selectedMechanic!,
      if (_selectedEquipment != null) 'equipment': _selectedEquipment!,
      if (_selectedPrimaryMuscle != null) 'primaryMuscle': _selectedPrimaryMuscle!,
      if (_selectedCategory != null) 'category': _selectedCategory!,
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
      } else {
        print("Failed to fetch exercises: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching exercise: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildDropdown<T>(String label, T? selected, List<T> options, ValueChanged<T?> onChanged) {
    return DropdownButton<T>(
      hint: Text(label),
      value: selected,
      onChanged: onChanged,
      items: options.map((T value) {
        return DropdownMenuItem<T>(
          value: value,
          child: Text(value.toString()),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fitness Exercises')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
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
                Wrap(
                  spacing: 10,
                  children: [
                    _buildDropdown('Level', _selectedLevel, ['beginner', 'intermediate', 'expert'], (val) {
                      setState(() => _selectedLevel = val);
                      _fetchExercises();
                    }),
                    _buildDropdown('Mechanic', _selectedMechanic, ['null', 'isolation', 'compound'], (val) {
                      setState(() => _selectedMechanic = val);
                      _fetchExercises();
                    }),
                    _buildDropdown('Equipment', _selectedEquipment, ['null', 'medicine ball', 'dumbbell', 'body only', 'bands', 'kettlebells', 'foam roll', 'cable', 'machine', 'barbell', 'exercise ball', 'e-z curl bar', 'other'], (val) {
                      setState(() => _selectedEquipment = val);
                      _fetchExercises();
                    }),
                    _buildDropdown('Primary Muscle', _selectedPrimaryMuscle, ["abdominals", "abductors", "adductors", "biceps", "calves", "chest", "forearms", "glutes", "hamstrings", "lats", "lower back", "middle back", "neck", "quadriceps", "shoulders", "traps", "triceps"], (val) {
                      setState(() => _selectedPrimaryMuscle = val);
                      _fetchExercises();
                    }),
                    _buildDropdown('Category', _selectedCategory, ["powerlifting", "strength", "stretching", "cardio", "olympic weightlifting", "strongman", "plyometrics"], (val) {
                      setState(() => _selectedCategory = val);
                      _fetchExercises();
                    }),
                  ],
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
