import 'dart:convert';
import 'package:flutter/material.dart';

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
            // --- IMAGE SECTION (hidden, but kept in code for future use) ---
            /*
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.blue[50],
                image: meal['image_url'] != null
                    ? DecorationImage(
                        image: NetworkImage(meal['image_url']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: meal['image_url'] == null
                  ? Center(
                      child: Icon(Icons.restaurant_menu, size: 64, color: Colors.blueAccent[100]),
                    )
                  : null,
            ),
            const SizedBox(height: 22),
            */
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              shadowColor: Colors.blueAccent.withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.all(22.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['title'] ?? '',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      meal['description'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      icon: Icons.shopping_basket,
                      color: Colors.orange,
                      title: 'Ingredients',
                    ),
                    const SizedBox(height: 4),
                    Text(meal['ingredients'] ?? '', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      icon: Icons.menu_book,
                      color: Colors.blueAccent,
                      title: 'Instructions',
                    ),
                    const SizedBox(height: 4),
                    Text(meal['instructions'] ?? '', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 18),
                    _SectionHeader(
                      icon: Icons.local_fire_department,
                      color: Colors.redAccent,
                      title: 'Nutrition Info',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutritionChip(
                          icon: Icons.local_fire_department,
                          label: 'Calories',
                          value: _extractNutrition(meal['nutrition_info'], 'calories'),
                          color: Colors.deepOrange,
                        ),
                        _NutritionChip(
                          icon: Icons.fitness_center,
                          label: 'Protein',
                          value: _extractNutrition(meal['nutrition_info'], 'protein'),
                          color: Colors.green,
                        ),
                        _NutritionChip(
                          icon: Icons.bubble_chart,
                          label: 'Carbs',
                          value: _extractNutrition(meal['nutrition_info'], 'carbs'),
                          color: Colors.blue,
                        ),
                        _NutritionChip(
                          icon: Icons.oil_barrel,
                          label: 'Fat',
                          value: _extractNutrition(meal['nutrition_info'], 'fat'),
                          color: Colors.purple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 36),
            // --- START COOKING BUTTON (hidden, but kept in code for future use) ---
            /*
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Cooking', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 6,
                shadowColor: Colors.green.withOpacity(0.2),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enjoy your meal!')),
                );
              },
            ),
            */
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.color,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _NutritionChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

String _extractNutrition(String? info, String key) {
  if (info == null) return '-';
  try {
    final Map<String, dynamic> nutrition = jsonDecode(info);
    final lowerKey = key.toLowerCase();
    if (nutrition.containsKey(lowerKey)) {
      return '${nutrition[lowerKey]}';
    }
  } catch (e) {
    return '-';
  }
  return '-';
}
