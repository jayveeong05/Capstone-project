import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- MODELS ---
class Ingredient {
  final String id;
  final String name;
  final String? category;
  final String? nutritionalValue;
  final String? allergenInfo;

  Ingredient({
    required this.id,
    required this.name,
    this.category,
    this.nutritionalValue,
    this.allergenInfo,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['ingredient_id'],
      name: json['name'],
      category: json['category'],
      nutritionalValue: json['nutritional_value'],
      allergenInfo: json['allergen_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'nutritional_value': nutritionalValue,
      'allergen_info': allergenInfo,
    };
  }
}

class Recipe {
  final String id;
  final String title;
  final String? description;
  final String? ingredients;
  final String? instructions;
  final String? nutritionInfo;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.title,
    this.description,
    this.ingredients,
    this.instructions,
    this.nutritionInfo,
    this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['recipe_id'],
      title: json['title'],
      description: json['description'],
      ingredients: json['ingredients'],
      instructions: json['instructions'],
      nutritionInfo: json['nutrition_info'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'nutrition_info': nutritionInfo,
      'image_url': imageUrl,
    };
  }
}


// --- MAIN PAGE WIDGET ---
class RecipeLibraryManagementPage extends StatefulWidget {
  const RecipeLibraryManagementPage({Key? key}) : super(key: key);

  @override
  _RecipeLibraryManagementPageState createState() =>
      _RecipeLibraryManagementPageState();
}

class _RecipeLibraryManagementPageState extends State<RecipeLibraryManagementPage> {
  static const String _backendBaseUrl = 'http://10.0.2.2:5000';
  
  bool _isLoading = true;
  List<Ingredient> _ingredients = [];
  List<Ingredient> _filteredIngredients = [];
  List<Recipe> _recipes = [];
  List<Recipe> _filteredRecipes = [];

  final _ingredientSearchController = TextEditingController();
  final _recipeSearchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchData();
    _ingredientSearchController.addListener(_filterIngredients);
    _recipeSearchController.addListener(_filterRecipes);
  }

  @override
  void dispose() {
    _ingredientSearchController.dispose();
    _recipeSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await _fetchIngredients();
      await _fetchRecipes();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _filterIngredients() {
    final query = _ingredientSearchController.text.toLowerCase();
    setState(() {
      _filteredIngredients = _ingredients
          .where((ingredient) => ingredient.name.toLowerCase().contains(query))
          .toList();
    });
  }

  void _filterRecipes() {
    final query = _recipeSearchController.text.toLowerCase();
    setState(() {
      _filteredRecipes = _recipes
          .where((recipe) => recipe.title.toLowerCase().contains(query))
          .toList();
    });
  }


  Future<void> _showIngredientForm({Ingredient? ingredient}) async {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: ingredient?.name);
    final _categoryController = TextEditingController(text: ingredient?.category);
    final _nutritionController = TextEditingController(text: ingredient?.nutritionalValue);
    final _allergenController = TextEditingController(text: ingredient?.allergenInfo);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(ingredient == null ? 'Create Ingredient' : 'Edit Ingredient'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Name is required' : null,
                  ),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  TextFormField(
                    controller: _nutritionController,
                    decoration: const InputDecoration(labelText: 'Nutritional Value'),
                  ),
                   TextFormField(
                    controller: _allergenController,
                    decoration: const InputDecoration(labelText: 'Allergen Info'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newIngredient = Ingredient(
                    id: ingredient?.id ?? '',
                    name: _nameController.text,
                    category: _categoryController.text,
                    nutritionalValue: _nutritionController.text,
                    allergenInfo: _allergenController.text,
                  );
                  try {
                    final url = ingredient == null
                        ? '$_backendBaseUrl/api/admin/ingredients'
                        : '$_backendBaseUrl/api/admin/ingredients/${ingredient.id}';
                    final response = await (ingredient == null
                        ? http.post(Uri.parse(url),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode(newIngredient.toJson()))
                        : http.put(Uri.parse(url),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode(newIngredient.toJson())));
                    
                    if (response.statusCode >= 200 && response.statusCode < 300) {
                      Navigator.pop(context);
                      _fetchIngredients(); // Refresh list
                    } else {
                      // Show error
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ${response.body}')));
                    }
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRecipeForm({Recipe? recipe}) async {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController(text: recipe?.title);
    final _descriptionController = TextEditingController(text: recipe?.description);
    final _ingredientsController = TextEditingController(text: recipe?.ingredients);
    final _instructionsController = TextEditingController(text: recipe?.instructions);
    final _nutritionController = TextEditingController(text: recipe?.nutritionInfo);
    final _imageUrlController = TextEditingController(text: recipe?.imageUrl);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(recipe == null ? 'Create Recipe' : 'Edit Recipe'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value!.isEmpty ? 'Title is required' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                   TextFormField(
                    controller: _ingredientsController,
                    decoration: const InputDecoration(labelText: 'Ingredients (comma-separated)'),
                     maxLines: 2,
                  ),
                   TextFormField(
                    controller: _instructionsController,
                    decoration: const InputDecoration(labelText: 'Instructions'),
                     maxLines: 3,
                  ),
                   TextFormField(
                    controller: _nutritionController,
                    decoration: const InputDecoration(labelText: 'Nutrition Info (JSON format)'),
                  ),
                   TextFormField(
                    controller: _imageUrlController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final newRecipe = Recipe(
                    id: recipe?.id ?? '',
                    title: _titleController.text,
                    description: _descriptionController.text,
                    ingredients: _ingredientsController.text,
                    instructions: _instructionsController.text,
                    nutritionInfo: _nutritionController.text,
                    imageUrl: _imageUrlController.text,
                  );
                  try {
                    final url = recipe == null
                        ? '$_backendBaseUrl/api/admin/recipes'
                        : '$_backendBaseUrl/api/admin/recipes/${recipe.id}';
                    final response = await (recipe == null
                        ? http.post(Uri.parse(url),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode(newRecipe.toJson()))
                        : http.put(Uri.parse(url),
                            headers: {'Content-Type': 'application/json'},
                            body: json.encode(newRecipe.toJson())));
                    
                    if (response.statusCode >= 200 && response.statusCode < 300) {
                      Navigator.pop(context);
                      _fetchRecipes(); // Refresh list
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: ${response.body}')));
                    }
                  } catch (e) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recipe Library Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ingredients', icon: Icon(Icons.food_bank_outlined)),
              Tab(text: 'Recipes', icon: Icon(Icons.menu_book_outlined)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildIngredientsTab(),
            _buildRecipesTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            // Use DefaultTabController.of(context) which is guaranteed to be non-null here
            final tabController = DefaultTabController.of(context);
             if (tabController == null) return Container(); // Should not happen
            return FloatingActionButton(
              onPressed: () {
                if (tabController.index == 0) {
                  _showIngredientForm();
                } else {
                  _showRecipeForm();
                }
              },
              child: const Icon(Icons.add),
              tooltip: tabController.index == 0 ? 'Add Ingredient' : 'Add Recipe',
            );
          }
        ),
      ),
    );
  }

  // --- INGREDIENTS TAB ---
  Widget _buildIngredientsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _ingredientSearchController,
            decoration: InputDecoration(
              labelText: 'Search Ingredients',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredIngredients.isEmpty
                  ? const Center(child: Text('No ingredients found.'))
                  : ListView.builder(
            itemCount: _filteredIngredients.length,
            itemBuilder: (context, index) {
              final ingredient = _filteredIngredients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(ingredient.name),
                  subtitle: Text(ingredient.category ?? 'No category'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showIngredientForm(ingredient: ingredient),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem('ingredients', ingredient.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Future<void> _fetchIngredients() async {
    final response = await http.get(Uri.parse('$_backendBaseUrl/api/admin/ingredients'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      setState(() {
        _ingredients = jsonResponse.map((item) => Ingredient.fromJson(item)).toList();
        _filteredIngredients = _ingredients;
      });
    } else {
      throw Exception('Failed to load ingredients');
    }
  }


  // --- RECIPES TAB ---
  Widget _buildRecipesTab() {
     return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _recipeSearchController,
            decoration: InputDecoration(
              labelText: 'Search Recipes',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredRecipes.isEmpty
                  ? const Center(child: Text('No recipes found.'))
                  : ListView.builder(
            itemCount: _filteredRecipes.length,
            itemBuilder: (context, index) {
              final recipe = _filteredRecipes[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(recipe.title),
                  subtitle: Text(recipe.description ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis,),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showRecipeForm(recipe: recipe),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem('recipes', recipe.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _fetchRecipes() async {
    final response = await http.get(Uri.parse('$_backendBaseUrl/api/admin/recipes'));
    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
       setState(() {
        _recipes = jsonResponse.map((item) => Recipe.fromJson(item)).toList();
        _filteredRecipes = _recipes;
      });
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  // --- COMMON DELETE FUNCTION ---
  Future<void> _deleteItem(String type, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${type.substring(0, type.length - 1)}?'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final url = '$_backendBaseUrl/api/admin/$type/$id';
        final response = await http.delete(Uri.parse(url));

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item deleted successfully')));
          if (type == 'ingredients') {
            _fetchIngredients();
          } else {
            _fetchRecipes();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error deleting item: ${response.body}')));
        }
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
