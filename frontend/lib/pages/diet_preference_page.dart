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
      appBar: AppBar(title: const Text('Diet Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Diet Type'),
                  value: _dietType,
                  items: dietTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) => setState(() => _dietType = val!),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Dietary Goal'),
                  value: _dietaryGoal,
                  items: goals.map((goal) {
                    return DropdownMenuItem(value: goal, child: Text(goal));
                  }).toList(),
                  onChanged: (val) => setState(() => _dietaryGoal = val!),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Cultural Restriction'),
                  value: _culturalRestriction,
                  items: culturalRestrictions.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r));
                  }).toList(),
                  onChanged: (val) => setState(() => _culturalRestriction = val!),
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Allergies (comma-separated)',
                  ),
                  onChanged: (val) => _allergies = val,
                ),
                const SizedBox(height: 20),
                const Text('Ingredient Preferences'),
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
                            decoration: const InputDecoration(labelText: 'Ingredient Name'),
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
                      icon: const Icon(Icons.add),
                      onPressed: _addIngredientPreference,
                    )
                  ],
                ),
                if (_ingredientPreferences.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _ingredientPreferences.map((pref) => ListTile(
                      title: Text('${pref['ingredient_name']} (${pref['preference_type']})'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => _ingredientPreferences.remove(pref)),
                      ),
                    )).toList(),
                  ),
                const SizedBox(height: 20),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _loading ? null : _submitPreferences,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Save & Generate Plan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
