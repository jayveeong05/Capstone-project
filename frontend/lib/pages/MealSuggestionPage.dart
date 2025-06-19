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

  // Add a list of common ingredients
  final List<String> _commonIngredients = [
    'egg', 'chicken', 'rice', 'tomato', 'onion', 'potato', 'cheese', 'milk', 'bread', 'beef', 'carrot', 'spinach', 'garlic', 'pepper', 'fish'
  ];

  void _addIngredient([String? ingredient]) {
    final value = (ingredient ?? _ingredientController.text).trim().toLowerCase();
    if (value.isNotEmpty && !_ingredients.contains(value)) {
      setState(() {
        _ingredients.add(value);
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
            Text('Select or enter available ingredients:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
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
                  onPressed: () => _addIngredient(),
                ),
              ],
            ),
            // Expandable selection card for common ingredients
            ExpansionTile(
              title: Text("Choose from common ingredients"),
              leading: Icon(Icons.list_alt),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _commonIngredients.map((ingredient) {
                    final isSelected = _ingredients.contains(ingredient);
                    return FilterChip(
                      label: Text(ingredient),
                      selected: isSelected,
                      selectedColor: Colors.blueAccent.withOpacity(0.7),
                      onSelected: (selected) {
                        if (selected && !isSelected) {
                          _addIngredient(ingredient);
                        } else if (!selected && isSelected) {
                          _removeIngredient(ingredient);
                        }
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 8),
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
            else
              Expanded(
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['title'] ?? '',
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal['description'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Divider(height: 28, thickness: 1.2),
                    Row(
                      children: [
                        Icon(Icons.shopping_basket, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(meal['ingredients'] ?? '', style: TextStyle(fontSize: 15)),
                    const Divider(height: 28, thickness: 1.2),
                    Row(
                      children: [
                        Icon(Icons.menu_book, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(meal['instructions'] ?? '', style: TextStyle(fontSize: 15)),
                    const Divider(height: 28, thickness: 1.2),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text('Nutrition Info:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Improved Nutrition Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _NutritionItem(
                            icon: Icons.local_fire_department,
                            label: 'Calories',
                            value: _extractNutrition(meal['nutrition_info'], 'Calories'),
                            color: Colors.deepOrange,
                          ),
                          _NutritionItem(
                            icon: Icons.fitness_center,
                            label: 'Protein',
                            value: _extractNutrition(meal['nutrition_info'], 'Protein'),
                            color: Colors.green,
                          ),
                          _NutritionItem(
                            icon: Icons.bubble_chart,
                            label: 'Carbs',
                            value: _extractNutrition(meal['nutrition_info'], 'Carbs'),
                            color: Colors.blue,
                          ),
                          _NutritionItem(
                            icon: Icons.oil_barrel,
                            label: 'Fat',
                            value: _extractNutrition(meal['nutrition_info'], 'Fat'),
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Cooking', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 3,
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

class _NutritionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _NutritionItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }
}

// Helper function to extract nutrition values from the string
String _extractNutrition(String? info, String key) {
  if (info == null) return '-';
  final regex = RegExp('$key: *([\\d.]+\\w*)', caseSensitive: false);
  final match = regex.firstMatch(info);
  return match != null ? match.group(1)! : '-';
}