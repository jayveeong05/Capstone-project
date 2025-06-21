"""
diet_db_init.py
Utility to (re)initialize all diet plan related tables for NextGenFitness.
"""

def init_diet_plan_tables(get_db_connection):
    """Reinitialize all diet plan related tables (drops existing ones first)"""
    conn = get_db_connection()
    c = conn.cursor()

    # Drop existing tables (in reverse dependency order)
    c.execute('DROP TABLE IF EXISTS RecipeIngredient')
    c.execute('DROP TABLE IF EXISTS DietPreferenceIngredient')
    c.execute('DROP TABLE IF EXISTS Ingredient')
    c.execute('DROP TABLE IF EXISTS RecipeLibrary')
    c.execute('DROP TABLE IF EXISTS UserDietPlanProgress')
    c.execute('DROP TABLE IF EXISTS NutritionTargets')
    c.execute('DROP TABLE IF EXISTS MealPlan')
    c.execute('DROP TABLE IF EXISTS DietPlan')
    c.execute('DROP TABLE IF EXISTS UserDietPreference')

    # DietPlan table
    c.execute('''CREATE TABLE DietPlan (
                    diet_plan_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    plan_name TEXT,
                    description TEXT,
                    daily_calories INTEGER,
                    duration_days INTEGER DEFAULT 7,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status TEXT DEFAULT 'Active',
                    FOREIGN KEY (user_id) REFERENCES User(user_id))''')

    # MealPlan table
    c.execute('''CREATE TABLE MealPlan (
                    meal_plan_id TEXT PRIMARY KEY,
                    diet_plan_id TEXT NOT NULL,
                    day_number INTEGER NOT NULL,
                    meal_type TEXT NOT NULL,
                    recipe_id TEXT NOT NULL,
                    serving_size REAL DEFAULT 1.0,
                    calories INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id),
                    FOREIGN KEY (recipe_id) REFERENCES RecipeLibrary(recipe_id))''')

    # NutritionTargets table
    c.execute('''CREATE TABLE NutritionTargets (
                    target_id TEXT PRIMARY KEY,
                    diet_plan_id TEXT NOT NULL,
                    daily_calories INTEGER,
                    protein_grams INTEGER,
                    carbs_grams INTEGER,
                    fat_grams INTEGER,
                    fiber_grams INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id))''')

    # UserDietPlanProgress table
    c.execute('''CREATE TABLE UserDietPlanProgress (
                    progress_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    diet_plan_id TEXT NOT NULL,
                    date DATE NOT NULL,
                    calories_consumed INTEGER DEFAULT 0,
                    meals_completed INTEGER DEFAULT 0,
                    weight REAL,
                    notes TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(user_id, diet_plan_id, date),
                    FOREIGN KEY (user_id) REFERENCES User(user_id),
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id))''')

    # UserDietPreference table
    c.execute('''CREATE TABLE UserDietPreference (
                    diet_pref_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    diet_type TEXT,
                    dietary_goal TEXT,
                    allergies TEXT,
                    calories INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES User(user_id))''')

    # Ingredient table
    c.execute('''CREATE TABLE Ingredient (
                    ingredient_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    category TEXT,
                    nutritional_value TEXT,
                    allergen_info TEXT);''')

    # RecipeLibrary table
    c.execute('''CREATE TABLE RecipeLibrary (
                    recipe_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    ingredients TEXT,
                    instructions TEXT,
                    nutrition_info TEXT,
                    image_url TEXT);''')

    # DietPreferenceIngredient table
    c.execute('''CREATE TABLE DietPreferenceIngredient (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    diet_pref_id TEXT NOT NULL,
                    ingredient_id TEXT NOT NULL,
                    preference_type TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_pref_id) REFERENCES UserDietPreference(diet_pref_id),
                    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id))''')

    # RecipeIngredient table
    c.execute('''CREATE TABLE RecipeIngredient (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    recipe_id TEXT NOT NULL,
                    ingredient_id TEXT NOT NULL,
                    quantity TEXT,
                    unit TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (recipe_id) REFERENCES RecipeLibrary(recipe_id),
                    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id))''')

    # Indexes for performance
    c.execute('CREATE INDEX IF NOT EXISTS idx_diet_plan_user ON DietPlan(user_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_meal_plan_diet ON MealPlan(diet_plan_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_progress_user_date ON UserDietPlanProgress(user_id, date)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_progress_diet_plan ON UserDietPlanProgress(diet_plan_id)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_diet_pref_user ON UserDietPreference(user_id)')

    conn.commit()

    # --- Insert sample data into Ingredient ---
    c.executemany(
        '''INSERT OR REPLACE INTO Ingredient (ingredient_id, name, category, nutritional_value, allergen_info)
           VALUES (?, ?, ?, ?, ?)''',
        [
            ('ING001', 'Chicken Breast', 'Meat', '{"protein": 31, "fat": 3.6, "calories": 165}', 'None'),
            ('ING002', 'Broccoli', 'Vegetable', '{"carbs": 6, "fiber": 2.4, "calories": 55}', 'None'),
            ('ING003', 'Brown Rice', 'Grains', '{"carbs": 45, "fiber": 3.5, "calories": 216}', 'Gluten'),
            ('ING004', 'Salmon', 'Fish', '{"protein": 25, "fat": 14, "calories": 208}', 'Fish'),
            ('ING005', 'Avocado', 'Fruit', '{"fat": 15, "fiber": 7, "calories": 160}', 'None'),
        ]
    )

    # --- Insert sample data into RecipeLibrary ---
    c.executemany(
        '''INSERT OR REPLACE INTO RecipeLibrary (recipe_id, title, description, ingredients, instructions, nutrition_info, image_url)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
            (
                'RCP001',
                'Grilled Chicken Bowl',
                'A high-protein meal perfect for lunch.',
                'Chicken Breast, Broccoli, Brown Rice',
                'Grill chicken, steam broccoli, cook rice, combine all in a bowl.',
                '{"calories": 436, "protein": 40, "carbs": 45, "fat": 10}',
                './backend/recipe_images/RCP001.jpg'
            ),
            (
                'RCP002',
                'Salmon Avocado Salad',
                'Omega-3 rich, low-carb salad.',
                'Salmon, Avocado, Broccoli',
                'Pan-fry salmon, slice avocado, toss all with steamed broccoli.',
                '{"calories": 420, "protein": 35, "carbs": 10, "fat": 28}',
                './backend/recipe_images/RCP002.jpg'
            ),
        ]
    )

    conn.commit()

    # --- Insert more sample data into Ingredient ---
    c.executemany(
        '''INSERT OR REPLACE INTO Ingredient (ingredient_id, name, category, nutritional_value, allergen_info)
           VALUES (?, ?, ?, ?, ?)''',
        [
            # ...existing ingredients...
            ('ING006', 'Egg', 'Dairy', '{"protein": 6, "fat": 5, "calories": 68}', 'Egg'),
            ('ING007', 'Spinach', 'Vegetable', '{"carbs": 1.1, "fiber": 0.7, "calories": 23}', 'None'),
            ('ING008', 'Quinoa', 'Grains', '{"carbs": 21, "fiber": 2.8, "calories": 120}', 'None'),
            ('ING009', 'Almonds', 'Nuts', '{"protein": 6, "fat": 14, "calories": 164}', 'Nuts'),
            ('ING010', 'Greek Yogurt', 'Dairy', '{"protein": 10, "fat": 0.4, "calories": 59}', 'Milk'),
            ('ING011', 'Sweet Potato', 'Vegetable', '{"carbs": 20, "fiber": 3, "calories": 86}', 'None'),
            ('ING012', 'Tofu', 'Soy', '{"protein": 8, "fat": 4.8, "calories": 76}', 'Soy'),
            ('ING013', 'Apple', 'Fruit', '{"carbs": 25, "fiber": 4.4, "calories": 95}', 'None'),
            ('ING014', 'Peanut Butter', 'Nuts', '{"protein": 8, "fat": 16, "calories": 188}', 'Peanuts'),
            ('ING015', 'Oats', 'Grains', '{"carbs": 27, "fiber": 4, "calories": 150}', 'Gluten'),
            ('ING016', 'Banana', 'Fruit', '{"carbs": 27, "fiber": 3, "calories": 105}', 'None'),
            ('ING017', 'Tomato', 'Vegetable', '{"carbs": 4, "fiber": 1.5, "calories": 22}', 'None'),
            ('ING018', 'Cheese', 'Dairy', '{"protein": 7, "fat": 9, "calories": 113}', 'Milk'),
            ('ING019', 'Turkey Breast', 'Meat', '{"protein": 29, "fat": 1, "calories": 135}', 'None'),
            ('ING020', 'Whole Wheat Bread', 'Grains', '{"carbs": 12, "fiber": 2, "calories": 69}', 'Gluten'),
            ('ING021', 'Lettuce', 'Vegetable', '{"carbs": 2, "fiber": 1, "calories": 8}', 'None'),
            ('ING022', 'Carrot', 'Vegetable', '{"carbs": 10, "fiber": 2.8, "calories": 41}', 'None'),
            ('ING023', 'Cucumber', 'Vegetable', '{"carbs": 4, "fiber": 0.5, "calories": 16}', 'None'),
            ('ING024', 'Shrimp', 'Seafood', '{"protein": 24, "fat": 0.3, "calories": 99}', 'Shellfish'),
            ('ING025', 'Pasta', 'Grains', '{"carbs": 31, "fiber": 2, "calories": 157}', 'Gluten'),
            ('ING026', 'Beef', 'Meat', '{"protein": 26, "fat": 15, "calories": 250}', 'None'),
            ('ING027', 'Bell Pepper', 'Vegetable', '{"carbs": 6, "fiber": 2, "calories": 25}', 'None'),
            ('ING028', 'Mushroom', 'Vegetable', '{"carbs": 3, "fiber": 1, "calories": 22}', 'None'),
            ('ING029', 'Milk', 'Dairy', '{"protein": 8, "fat": 5, "calories": 103}', 'Milk'),
            ('ING030', 'Blueberry', 'Fruit', '{"carbs": 14, "fiber": 2.4, "calories": 57}', 'None'),
            ('ING031', 'Walnut', 'Nuts', '{"protein": 4, "fat": 18, "calories": 185}', 'Nuts'),
            ('ING032', 'Honey', 'Sweetener', '{"carbs": 17, "calories": 64}', 'None'),
            ('ING033', 'Chickpea', 'Legume', '{"protein": 3, "carbs": 9, "calories": 46}', 'None'),
            ('ING034', 'Zucchini', 'Vegetable', '{"carbs": 3, "fiber": 1, "calories": 17}', 'None'),
            ('ING035', 'Mayonnaise', 'Condiment', '{"fat": 10, "calories": 90}', 'Egg'),
            ('ING036', 'Cod', 'Fish', '{"protein": 20, "fat": 0.7, "calories": 89}', 'Fish'),
            ('ING037', 'Potato', 'Vegetable', '{"carbs": 17, "fiber": 2.2, "calories": 77}', 'None'),
            ('ING038', 'Eggplant', 'Vegetable', '{"carbs": 6, "fiber": 3, "calories": 25}', 'None'),
            ('ING039', 'Rice', 'Grains', '{"carbs": 28, "fiber": 0.4, "calories": 130}', 'None'),
            ('ING040', 'Lentil', 'Legume', '{"protein": 9, "carbs": 20, "calories": 116}', 'None'),
        ]
    )

    # --- Insert 10 breakfast recipes ---
    breakfast_recipes = [
        (
            'RCP101', 'Oatmeal Banana Bowl', 'A hearty and healthy breakfast.',
            'Oats, Banana, Almonds, Milk',
            'Cook oats with milk, top with banana slices and almonds.',
            '{"calories": 320, "protein": 10, "carbs": 55, "fat": 8}',
            './backend/recipe_images/RCP101.jpg'
        ),
        (
            'RCP102', 'Spinach Omelette', 'Protein-rich omelette with greens.',
            'Egg, Spinach, Cheese',
            'Beat eggs, add spinach and cheese, cook in pan.',
            '{"calories": 250, "protein": 16, "carbs": 3, "fat": 18}',
            './backend/recipe_images/RCP102.jpg'
        ),
        (
            'RCP103', 'Greek Yogurt Parfait', 'Layered yogurt with fruit and nuts.',
            'Greek Yogurt, Blueberry, Almonds',
            'Layer yogurt, blueberries, and almonds in a glass.',
            '{"calories": 210, "protein": 13, "carbs": 20, "fat": 8}',
            './backend/recipe_images/RCP103.jpg'
        ),
        (
            'RCP104', 'Peanut Butter Toast', 'Quick energy breakfast.',
            'Whole Wheat Bread, Peanut Butter, Banana',
            'Toast bread, spread peanut butter, top with banana slices.',
            '{"calories": 280, "protein": 9, "carbs": 35, "fat": 12}',
            './backend/recipe_images/RCP104.jpg'
        ),
        (
            'RCP105', 'Veggie Scramble', 'Egg scramble with mixed veggies.',
            'Egg, Tomato, Bell Pepper, Mushroom',
            'Scramble eggs, add chopped veggies, cook until done.',
            '{"calories": 190, "protein": 12, "carbs": 7, "fat": 12}',
            './backend/recipe_images/RCP105.jpg'
        ),
        (
            'RCP106', 'Avocado Toast', 'Healthy fats to start your day.',
            'Whole Wheat Bread, Avocado, Tomato',
            'Toast bread, mash avocado, top with tomato slices.',
            '{"calories": 240, "protein": 6, "carbs": 28, "fat": 12}',
            './backend/recipe_images/RCP106.jpg'
        ),
        (
            'RCP107', 'Apple Cinnamon Oats', 'Warm oats with apple and spice.',
            'Oats, Apple, Milk',
            'Cook oats with milk and diced apple, sprinkle cinnamon.',
            '{"calories": 260, "protein": 8, "carbs": 48, "fat": 5}',
            './backend/recipe_images/RCP107.jpg'
        ),
        (
            'RCP108', 'Breakfast Burrito', 'Egg and veggie wrap.',
            'Egg, Spinach, Tomato, Whole Wheat Bread',
            'Scramble eggs with spinach and tomato, wrap in bread.',
            '{"calories": 300, "protein": 14, "carbs": 32, "fat": 12}',
            './backend/recipe_images/RCP108.jpg'
        ),
        (
            'RCP109', 'Berry Smoothie', 'Refreshing fruit smoothie.',
            'Milk, Blueberry, Banana',
            'Blend milk, blueberries, and banana until smooth.',
            '{"calories": 180, "protein": 6, "carbs": 35, "fat": 3}',
            './backend/recipe_images/RCP109.jpg'
        ),
        (
            'RCP110', 'Egg Muffins', 'Portable baked eggs with veggies.',
            'Egg, Spinach, Bell Pepper, Cheese',
            'Mix eggs, veggies, cheese, bake in muffin tin.',
            '{"calories": 120, "protein": 8, "carbs": 3, "fat": 8}',
            './backend/recipe_images/RCP110.jpg'
        ),
    ]

    # --- Insert 10 lunch recipes ---
    lunch_recipes = [
        (
            'RCP201', 'Chicken Quinoa Salad', 'Protein-packed salad.',
            'Chicken Breast, Quinoa, Spinach, Tomato',
            'Grill chicken, cook quinoa, toss with spinach and tomato.',
            '{"calories": 410, "protein": 35, "carbs": 38, "fat": 12}',
            './backend/recipe_images/RCP201.jpg'
        ),
        (
            'RCP202', 'Turkey Sandwich', 'Lean turkey with veggies.',
            'Turkey Breast, Whole Wheat Bread, Lettuce, Tomato',
            'Layer turkey, lettuce, tomato on bread.',
            '{"calories": 320, "protein": 28, "carbs": 34, "fat": 6}',
            './backend/recipe_images/RCP202.jpg'
        ),
        (
            'RCP203', 'Salmon Rice Bowl', 'Omega-3 rich lunch.',
            'Salmon, Brown Rice, Broccoli',
            'Bake salmon, steam broccoli, serve over rice.',
            '{"calories": 480, "protein": 32, "carbs": 50, "fat": 14}',
            './backend/recipe_images/RCP203.jpg'
        ),
        (
            'RCP204', 'Veggie Pasta', 'Vegetarian pasta with veggies.',
            'Pasta, Tomato, Bell Pepper, Mushroom',
            'Cook pasta, sauté veggies, mix together.',
            '{"calories": 350, "protein": 10, "carbs": 60, "fat": 7}',
            './backend/recipe_images/RCP204.jpg'
        ),
        (
            'RCP205', 'Shrimp Stir Fry', 'Quick stir fry with shrimp.',
            'Shrimp, Broccoli, Carrot, Bell Pepper',
            'Stir fry shrimp and veggies, serve hot.',
            '{"calories": 290, "protein": 22, "carbs": 18, "fat": 10}',
            './backend/recipe_images/RCP205.jpg'
        ),
        (
            'RCP206', 'Beef & Veggie Bowl', 'Hearty beef with vegetables.',
            'Beef, Brown Rice, Broccoli, Carrot',
            'Cook beef, steam veggies, serve over rice.',
            '{"calories": 520, "protein": 30, "carbs": 48, "fat": 20}',
            './backend/recipe_images/RCP206.jpg'
        ),
        (
            'RCP207', 'Tofu Buddha Bowl', 'Vegan lunch bowl.',
            'Tofu, Quinoa, Spinach, Avocado',
            'Cook tofu and quinoa, serve with spinach and avocado.',
            '{"calories": 400, "protein": 16, "carbs": 45, "fat": 16}',
            './backend/recipe_images/RCP207.jpg'
        ),
        (
            'RCP208', 'Chicken Wrap', 'Grilled chicken in a wrap.',
            'Chicken Breast, Lettuce, Tomato, Whole Wheat Bread',
            'Grill chicken, wrap with lettuce and tomato in bread.',
            '{"calories": 350, "protein": 28, "carbs": 32, "fat": 8}',
            './backend/recipe_images/RCP208.jpg'
        ),
        (
            'RCP209', 'Egg Fried Rice', 'Quick and easy fried rice.',
            'Egg, Brown Rice, Carrot, Peas',
            'Scramble eggs, stir fry with rice and veggies.',
            '{"calories": 370, "protein": 12, "carbs": 60, "fat": 8}',
            './backend/recipe_images/RCP209.jpg'
        ),
        (
            'RCP210', 'Lentil Soup', 'Hearty vegetarian soup.',
            'Lentil, Carrot, Tomato, Spinach',
            'Cook lentils and veggies in broth.',
            '{"calories": 280, "protein": 14, "carbs": 45, "fat": 3}',
            './backend/recipe_images/RCP210.jpg'
        ),
    ]

    # --- Insert 10 dinner recipes ---
    dinner_recipes = [
        (
            'RCP301', 'Grilled Salmon & Veggies', 'Simple grilled salmon dinner.',
            'Salmon, Broccoli, Carrot, Bell Pepper',
            'Grill salmon, roast veggies, serve together.',
            '{"calories": 430, "protein": 34, "carbs": 22, "fat": 22}',
            './backend/recipe_images/RCP301.jpg'
        ),
        (
            'RCP302', 'Chicken Stir Fry', 'Classic chicken stir fry.',
            'Chicken Breast, Bell Pepper, Broccoli, Brown Rice',
            'Stir fry chicken and veggies, serve over rice.',
            '{"calories": 410, "protein": 32, "carbs": 45, "fat": 10}',
            './backend/recipe_images/RCP302.jpg'
        ),
        (
            'RCP303', 'Beef Stew', 'Comforting beef stew.',
            'Beef, Carrot, Potato, Onion',
            'Simmer beef and veggies in broth until tender.',
            '{"calories": 520, "protein": 28, "carbs": 40, "fat": 24}',
            './backend/recipe_images/RCP303.jpg'
        ),
        (
            'RCP304', 'Shrimp Pasta', 'Seafood pasta dinner.',
            'Shrimp, Pasta, Tomato, Spinach',
            'Cook pasta, sauté shrimp and veggies, mix together.',
            '{"calories": 390, "protein": 20, "carbs": 60, "fat": 7}',
            './backend/recipe_images/RCP304.jpg'
        ),
        (
            'RCP305', 'Stuffed Peppers', 'Peppers stuffed with rice and beef.',
            'Bell Pepper, Beef, Brown Rice, Tomato',
            'Stuff peppers with beef, rice, tomato, bake until tender.',
            '{"calories": 340, "protein": 18, "carbs": 38, "fat": 12}',
            './backend/recipe_images/RCP305.jpg'
        ),
        (
            'RCP306', 'Vegetable Curry', 'Spicy vegetarian curry.',
            'Potato, Carrot, Tomato, Spinach',
            'Cook veggies in curry sauce, serve with rice.',
            '{"calories": 310, "protein": 8, "carbs": 60, "fat": 6}',
            './backend/recipe_images/RCP306.jpg'
        ),
        (
            'RCP307', 'Tofu Stir Fry', 'Vegan stir fry for dinner.',
            'Tofu, Broccoli, Bell Pepper, Brown Rice',
            'Stir fry tofu and veggies, serve over rice.',
            '{"calories": 350, "protein": 14, "carbs": 50, "fat": 10}',
            './backend/recipe_images/RCP307.jpg'
        ),
        (
            'RCP308', 'Chicken & Sweet Potato', 'Balanced chicken dinner.',
            'Chicken Breast, Sweet Potato, Broccoli',
            'Bake chicken and sweet potato, steam broccoli.',
            '{"calories": 390, "protein": 32, "carbs": 40, "fat": 8}',
            './backend/recipe_images/RCP308.jpg'
        ),
        (
            'RCP309', 'Quinoa Veggie Bowl', 'Light and nutritious dinner.',
            'Quinoa, Spinach, Tomato, Avocado',
            'Cook quinoa, toss with veggies and avocado.',
            '{"calories": 320, "protein": 10, "carbs": 45, "fat": 10}',
            './backend/recipe_images/RCP309.jpg'
        ),
        (
            'RCP310', 'Eggplant Parmesan', 'Vegetarian Italian classic.',
            'Eggplant, Tomato, Cheese, Pasta',
            'Bake eggplant with tomato and cheese, serve with pasta.',
            '{"calories": 410, "protein": 16, "carbs": 55, "fat": 14}',
            './backend/recipe_images/RCP310.jpg'
        ),
    ]

    # --- Additional breakfast recipes ---
    more_breakfast = [
        (
            'RCP111', 'Blueberry Pancakes', 'Fluffy pancakes with blueberries.',
            'Oats, Milk, Egg, Blueberry',
            'Mix oats, milk, and egg, fold in blueberries, cook on skillet.',
            '{"calories": 290, "protein": 9, "carbs": 48, "fat": 7}',
            './backend/recipe_images/RCP111.jpg'
        ),
        (
            'RCP112', 'Tofu Breakfast Bowl', 'Vegan protein breakfast.',
            'Tofu, Spinach, Tomato, Avocado',
            'Sauté tofu and spinach, serve with tomato and avocado.',
            '{"calories": 260, "protein": 13, "carbs": 12, "fat": 16}',
            './backend/recipe_images/RCP112.jpg'
        ),
        (
            'RCP113', 'Egg & Veggie Wrap', 'Eggs and veggies in a wrap.',
            'Egg, Bell Pepper, Mushroom, Whole Wheat Bread',
            'Scramble eggs with veggies, wrap in bread.',
            '{"calories": 310, "protein": 14, "carbs": 34, "fat": 11}',
            './backend/recipe_images/RCP113.jpg'
        ),
        (
            'RCP114', 'Apple Walnut Oatmeal', 'Oatmeal with apple and walnuts.',
            'Oats, Apple, Walnut, Milk',
            'Cook oats with milk, stir in apple and walnuts.',
            '{"calories": 330, "protein": 8, "carbs": 52, "fat": 11}',
            './backend/recipe_images/RCP114.jpg'
        ),
        (
            'RCP115', 'Greek Yogurt & Honey', 'Simple yogurt breakfast.',
            'Greek Yogurt, Honey, Almonds',
            'Top yogurt with honey and almonds.',
            '{"calories": 220, "protein": 12, "carbs": 22, "fat": 7}',
            './backend/recipe_images/RCP115.jpg'
        ),
    ]

    # --- Additional lunch recipes ---
    more_lunch = [
        (
            'RCP211', 'Chickpea Salad', 'Plant-based protein salad.',
            'Chickpea, Tomato, Cucumber, Lettuce',
            'Mix chickpeas with chopped veggies and lettuce.',
            '{"calories": 340, "protein": 13, "carbs": 50, "fat": 8}',
            './backend/recipe_images/RCP211.jpg'
        ),
        (
            'RCP212', 'Egg Salad Sandwich', 'Classic egg salad on bread.',
            'Egg, Lettuce, Whole Wheat Bread, Mayonnaise',
            'Mix boiled eggs with mayo, serve on bread with lettuce.',
            '{"calories": 370, "protein": 15, "carbs": 32, "fat": 18}',
            './backend/recipe_images/RCP212.jpg'
        ),
        (
            'RCP213', 'Quinoa Veggie Bowl', 'Nutritious quinoa and veggies.',
            'Quinoa, Broccoli, Carrot, Avocado',
            'Cook quinoa, steam veggies, top with avocado.',
            '{"calories": 390, "protein": 11, "carbs": 60, "fat": 13}',
            './backend/recipe_images/RCP213.jpg'
        ),
        (
            'RCP214', 'Chicken Caesar Wrap', 'Chicken Caesar salad in a wrap.',
            'Chicken Breast, Lettuce, Cheese, Whole Wheat Bread',
            'Grill chicken, toss with lettuce and cheese, wrap in bread.',
            '{"calories": 410, "protein": 28, "carbs": 36, "fat": 15}',
            './backend/recipe_images/RCP214.jpg'
        ),
        (
            'RCP215', 'Lentil Veggie Soup', 'Hearty lentil and veggie soup.',
            'Lentil, Carrot, Tomato, Spinach',
            'Simmer lentils and veggies in broth.',
            '{"calories": 300, "protein": 13, "carbs": 48, "fat": 4}',
            './backend/recipe_images/RCP215.jpg'
        ),
    ]

    # --- Additional dinner recipes ---
    more_dinner = [
        (
            'RCP311', 'Baked Cod & Veggies', 'Lean fish with roasted vegetables.',
            'Cod, Broccoli, Carrot, Potato',
            'Bake cod and veggies together with herbs.',
            '{"calories": 370, "protein": 32, "carbs": 38, "fat": 9}',
            './backend/recipe_images/RCP311.jpg'
        ),
        (
            'RCP312', 'Stuffed Zucchini Boats', 'Zucchini stuffed with beef and rice.',
            'Zucchini, Beef, Brown Rice, Tomato',
            'Stuff zucchini with beef, rice, tomato, bake until tender.',
            '{"calories": 410, "protein": 20, "carbs": 44, "fat": 16}',
            './backend/recipe_images/RCP312.jpg'
        ),
        (
            'RCP313', 'Vegetable Stir Fry', 'Mixed veggies stir fried with tofu.',
            'Tofu, Broccoli, Bell Pepper, Carrot',
            'Stir fry tofu and veggies with soy sauce.',
            '{"calories": 330, "protein": 14, "carbs": 38, "fat": 12}',
            './backend/recipe_images/RCP313.jpg'
        ),
        (
            'RCP314', 'Chicken Alfredo Pasta', 'Creamy pasta with chicken.',
            'Chicken Breast, Pasta, Cheese, Milk',
            'Cook pasta, toss with grilled chicken and cheese sauce.',
            '{"calories": 520, "protein": 32, "carbs": 60, "fat": 16}',
            './backend/recipe_images/RCP314.jpg'
        ),
        (
            'RCP315', 'Mushroom Risotto', 'Creamy risotto with mushrooms.',
            'Rice, Mushroom, Cheese, Milk',
            'Cook rice slowly with mushrooms and cheese.',
            '{"calories": 410, "protein": 10, "carbs": 65, "fat": 12}',
            './backend/recipe_images/RCP315.jpg'
        ),
    ]

    # --- Insert all recipes ---
    c.executemany(
        '''INSERT OR REPLACE INTO RecipeLibrary (recipe_id, title, description, ingredients, instructions, nutrition_info, image_url)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        breakfast_recipes + lunch_recipes + dinner_recipes
    )

    # --- Insert all new recipes ---
    c.executemany(
        '''INSERT OR REPLACE INTO RecipeLibrary (recipe_id, title, description, ingredients, instructions, nutrition_info, image_url)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        more_breakfast + more_lunch + more_dinner
    )

    conn.commit()
    conn.close()
    print("All diet plan tables were dropped, reinitialized, and sample data inserted successfully!")

def get_db_connection():
    import sqlite3
    return sqlite3.connect('./backend/NextGenFitness.db')

if __name__ == "__main__":
    init_diet_plan_tables(get_db_connection)
