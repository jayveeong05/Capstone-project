import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'MealDetailPage.dart';

class MealPlansPage extends StatefulWidget {
  const MealPlansPage({super.key});

  @override
  _MealPlansPageState createState() => _MealPlansPageState();
}

class _MealPlansPageState extends State<MealPlansPage> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  List<String> _allIngredientNames = [];
  List<Map<String, dynamic>> _suggestedMeals = [];
  bool _loading = false;
  String? _error;

  final String _baseUrl = 'http://10.0.2.2:5000';

  @override
  void initState() {
    super.initState();
    _fetchAllIngredientNames();
    _fetchMealSuggestions();
  }

  Future<void> _fetchAllIngredientNames() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/ingredients'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _allIngredientNames = List<String>.from(data);
        });
      }
    } catch (e) {}
  }

  void _addIngredient(String value) {
    final input = value.trim().toLowerCase();
    if (input.isNotEmpty && !_ingredients.contains(input)) {
      setState(() {
        _ingredients.add(input);
        _ingredientController.clear();
      });
      _fetchMealSuggestions();
    }
  }

  void _removeIngredient(String ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
    });
    _fetchMealSuggestions();
  }

  Future<void> _fetchMealSuggestions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/suggest-meals'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ingredients': _ingredients}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestedMeals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
        });
      } else {
        setState(() {
          _error = 'Failed to fetch suggestions.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plans'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _ingredientController,
                        decoration: InputDecoration(
                          hintText: 'Enter ingredient...',
                          suffixIcon: PopupMenuButton<String>(
                            icon: Icon(Icons.arrow_drop_down),
                            onSelected: (value) {
                              _ingredientController.text = value;
                              _addIngredient(value);
                            },
                            itemBuilder: (BuildContext context) {
                              final query = _ingredientController.text.toLowerCase();
                              final filtered = _allIngredientNames.where((name) => name.toLowerCase().contains(query)).toList();
                              return filtered.map((name) => PopupMenuItem<String>(
                                value: name,
                                child: Text(name),
                              )).toList();
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                        onSubmitted: (value) => _addIngredient(value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: Icon(Icons.add, color: Colors.white),
                    onPressed: () => _addIngredient(_ingredientController.text),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _ingredients.map((ingredient) => Chip(
                label: Text(ingredient),
                backgroundColor: Colors.blueAccent.withOpacity(0.15),
                elevation: 2,
                deleteIcon: Icon(Icons.close, size: 18),
                onDeleted: () => _removeIngredient(ingredient),
              )).toList(),
            ),
            const SizedBox(height: 24),
            Text('Suggested Meals:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (_loading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: TextStyle(color: Colors.red)),
              )
            else if (_suggestedMeals.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('No suggestions yet. Add ingredients to see meal ideas.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _suggestedMeals.length,
                  itemBuilder: (context, index) {
                    final meal = _suggestedMeals[index];
                    final match = double.tryParse(meal['match_percentage'].toString()) ?? 0.0;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: match > 0 ? Colors.green : Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      elevation: 2,
                      child: ListTile(
                        leading: Icon(Icons.restaurant_menu, color: Colors.blueAccent, size: 32),
                        title: Text(meal['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['description'] ?? ''),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.verified, color: Colors.green, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Match: ${meal['match_percentage']}%',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: match / 100,
                                    backgroundColor: Colors.grey[200],
                                    color: match > 50 ? Colors.green : Colors.orange,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MealDetailPage(meal: meal),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
