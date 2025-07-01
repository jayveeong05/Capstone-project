import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DietPreferencePage extends StatefulWidget {
  final String userId;
  const DietPreferencePage({required this.userId, super.key});

  @override
  State<DietPreferencePage> createState() => _DietPreferencePageState();
}

class _DietPreferencePageState extends State<DietPreferencePage> {
  final _formKey = GlobalKey<FormState>();

  String _dietType = 'None';
  String _dietaryGoal = 'Weight Loss';
  String _culturalRestriction = 'None';
  String _allergies = '';
  List<Map<String, String>> _ingredientPreferences = [];
  final TextEditingController _ingredientController = TextEditingController();
  String _selectedPreferenceType = 'Like';

  List<String> _ingredientSuggestions = [];
  bool _loading = false;
  String? _error;

  final List<String> dietTypes = [
    'None',
    'Vegetarian',
    'Vegan',
    'Pescatarian',
    'High Protein',
    'Low Carb',
  ];

  final List<String> goals = [
    'Weight Loss',
    'Muscle Gain',
    'Maintain Weight',
    'General Fitness',
  ];

  final List<String> culturalRestrictions = [
    'None',
    'Halal',
    'Kosher',
  ];

  final List<String> preferenceTypes = [
    'Like',
    'Dislike',
    'Avoid'
  ];

  @override
  void initState() {
    super.initState();
    _fetchIngredientSuggestions();
  }

  Future<void> _fetchIngredientSuggestions() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/api/ingredients'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _ingredientSuggestions = List<String>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Failed to load ingredient suggestions: $e');
    }
  }

  void _addIngredientPreference() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty) {
      setState(() {
        _ingredientPreferences.add({
          'ingredient_name': ingredient,
          'preference_type': _selectedPreferenceType
        });
        _ingredientController.clear();
      });
    }
  }

  Future<void> _showPreviewDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Your Preferences'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Diet Type: $_dietType'),
                Text('Dietary Goal: $_dietaryGoal'),
                Text('Cultural Restriction: $_culturalRestriction'),
                Text('Allergies: ${_allergies.isEmpty ? 'None' : _allergies}'),
                const SizedBox(height: 10),
                const Text('Ingredient Preferences:'),
                ..._ingredientPreferences.map((pref) => Text(
                    '- ${pref['ingredient_name']} (${pref['preference_type']})')),
                const SizedBox(height: 10),
                const Text(
                  'Do you want to save and generate your diet plan?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                _finalSubmit();
              },
            ),
          ],
        );
      },
    );
  }

  void _submitPreferences() {
    if (_formKey.currentState!.validate()) {
      _showPreviewDialog();
    }
  }

  Future<void> _finalSubmit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefsResponse = await http.put(
        Uri.parse('http://10.0.2.2:5000/api/update-diet-preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'diet_type': _dietType,
          'dietary_goal': _dietaryGoal,
          'cultural_restriction': _culturalRestriction,
          'allergies': _allergies,
          'ingredient_preferences': _ingredientPreferences.map((pref) => {
            'ingredient_name': pref['ingredient_name'],
            'preference_type': pref['preference_type']
          }).toList()
        }),
      );

      if (prefsResponse.statusCode != 200) {
        final data = jsonDecode(prefsResponse.body);
        setState(() {
          _error = data['error'] ?? 'Failed to update preferences';
        });
        return;
      }

      final generateResponse = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/generate-diet-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'duration_days': 7,
          'plan_name': 'My Personalized Diet Plan',
        }),
      );

      if (generateResponse.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(generateResponse.body);
        setState(() {
          _error = data['error'] ?? 'Failed to generate plan';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
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
        title: const Text('Diet Preferences'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(icon: Icons.restaurant_menu, color: Colors.blue, title: 'Diet & Goal'),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Diet Type', border: OutlineInputBorder()),
                      value: _dietType,
                      items: dietTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (val) => setState(() => _dietType = val!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Dietary Goal', border: OutlineInputBorder()),
                      value: _dietaryGoal,
                      items: goals.map((goal) {
                        return DropdownMenuItem(value: goal, child: Text(goal));
                      }).toList(),
                      onChanged: (val) => setState(() => _dietaryGoal = val!),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Cultural Restriction', border: OutlineInputBorder()),
                      value: _culturalRestriction,
                      items: culturalRestrictions.map((r) {
                        return DropdownMenuItem(value: r, child: Text(r));
                      }).toList(),
                      onChanged: (val) => setState(() => _culturalRestriction = val!),
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(icon: Icons.warning_amber, color: Colors.redAccent, title: 'Allergies'),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Allergies (comma-separated)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _allergies = val,
                    ),
                    const SizedBox(height: 22),
                    _SectionHeader(icon: Icons.food_bank, color: Colors.green, title: 'Ingredient Preferences'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _ingredientSuggestions.where((option) =>
                                  option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              _ingredientController.text = controller.text;
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Ingredient Name',
                                  border: OutlineInputBorder(),
                                ),
                              );
                            },
                            onSelected: (String selection) {
                              _ingredientController.text = selection;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        DropdownButton<String>(
                          value: _selectedPreferenceType,
                          onChanged: (val) => setState(() => _selectedPreferenceType = val!),
                          items: preferenceTypes.map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          )).toList(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.blueAccent),
                          onPressed: _addIngredientPreference,
                          tooltip: 'Add Preference',
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_ingredientPreferences.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _ingredientPreferences.map((pref) => Chip(
                          label: Text('${pref['ingredient_name']} (${pref['preference_type']})'),
                          deleteIcon: const Icon(Icons.close),
                          onDeleted: () => setState(() => _ingredientPreferences.remove(pref)),
                          backgroundColor: pref['preference_type'] == 'Like'
                              ? Colors.green[50]
                              : pref['preference_type'] == 'Dislike'
                                  ? Colors.red[50]
                                  : Colors.orange[50],
                          labelStyle: TextStyle(
                            color: pref['preference_type'] == 'Like'
                                ? Colors.green[800]
                                : pref['preference_type'] == 'Dislike'
                                    ? Colors.red[800]
                                    : Colors.orange[800],
                          ),
                        )).toList(),
                      ),
                    const SizedBox(height: 24),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(_error!, style: const TextStyle(color: Colors.red)),
                      ),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                            : const Text('Save & Generate Plan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          elevation: 3,
                        ),
                        onPressed: _loading ? null : _submitPreferences,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for section headers
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
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
