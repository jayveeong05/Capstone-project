import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';


class MealPlansPage extends StatefulWidget {
  const MealPlansPage({super.key});

  @override
  _MealPlansPageState createState() => _MealPlansPageState();
}

class _MealPlansPageState extends State<MealPlansPage> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  List<Map<String, dynamic>> _suggestedMeals = [];
  bool _loading = false;
  String? _error;

  final String _baseUrl = 'http://10.0.2.2:5000'; // Change if backend runs elsewhere

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim().toLowerCase();
    if (ingredient.isNotEmpty && !_ingredients.contains(ingredient)) {
      setState(() {
        _ingredients.add(ingredient);
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
    if (_ingredients.isEmpty) {
      setState(() {
        _suggestedMeals = [];
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    print('Sending ingredients: $_ingredients');  // Debug print
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
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch suggestions.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
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
            Text('Enter available ingredients:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredientController,
                    decoration: InputDecoration(hintText: 'e.g. egg, chicken, rice'),
                    onSubmitted: (_) => _addIngredient(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addIngredient,
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: _ingredients.map((ingredient) => Chip(
                label: Text(ingredient),
                onDeleted: () => _removeIngredient(ingredient),
              )).toList(),
            ),
            SizedBox(height: 24),
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
            else              Expanded(
                child: ListView.builder(
                  itemCount: _suggestedMeals.length,
                  itemBuilder: (context, index) {
                    final meal = _suggestedMeals[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: ListTile(
                        leading: Icon(Icons.restaurant_menu),
                        title: Text(meal['title'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meal['description'] ?? ''),
                            SizedBox(height: 4),
                            Text(
                              'Match: ${meal['match_percentage']}%',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
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

class MealDetailPage extends StatelessWidget {
  final Map<String, dynamic> meal;

  const MealDetailPage({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(meal['title'] ?? 'Meal Detail'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              meal['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(meal['description'] ?? '', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Ingredients:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(meal['ingredients'] ?? ''),
            const SizedBox(height: 16),
            Text('Instructions:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(meal['instructions'] ?? ''),
            const SizedBox(height: 16),
            Text('Nutrition Info:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(meal['nutrition_info'] ?? ''),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Cooking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enjoy your meal!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}