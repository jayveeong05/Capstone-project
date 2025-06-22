# diet_plan_system.py
# Diet Plan Management System for NextGenFitness
# This module handles diet plan generation, meal planning, and nutrition tracking

import json
import sqlite3
import random
import math
import uuid
import re
import random
from datetime import datetime, date, timedelta
from collections import defaultdict
from flask import request, jsonify

# Import the database connection function from your main application
# from NextGenFitness import get_db_connection, app

class DietPlanSystem:
    """Main class for handling diet plan operations"""
    
    def __init__(self, db_connection_func):
        """Initialize with database connection function"""
        self.get_db_connection = db_connection_func
    
    def generate_diet_plan_id(self):
        """Generate unique diet plan ID"""
        conn = self.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT diet_plan_id FROM DietPlan ORDER BY diet_plan_id DESC LIMIT 1")
        last_id_row = c.fetchone()
        conn.close()
        if last_id_row:
            last_id = last_id_row['diet_plan_id']
            numeric_part = int(last_id[3:]) + 1
            return f'DPL{numeric_part:03d}'
        else:
            return 'DPL001'
    
    def generate_meal_plan_id(self):
        """Generate unique meal plan ID"""
        conn = self.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT meal_plan_id FROM MealPlan ORDER BY meal_plan_id DESC LIMIT 1")
        last_id_row = c.fetchone()
        conn.close()
        if last_id_row:
            last_id = last_id_row['meal_plan_id']
            numeric_part = int(last_id[2:]) + 1
            return f'MP{numeric_part:03d}'
        else:
            return 'MP001'
    
    def generate_diet_pref_id(self):
        """Generate unique diet preference ID"""
        conn = self.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT diet_pref_id FROM UserDietPreference ORDER BY diet_pref_id DESC LIMIT 1")
        last_id_row = c.fetchone()
        conn.close()
        if last_id_row:
            last_id = last_id_row['diet_pref_id']
            numeric_part = int(last_id[2:]) + 1
            return f'DP{numeric_part:03d}'
        else:
            return 'DP001'
    
    def get_user_dietary_preferences(self, user_id):
        """Get user's dietary preferences and goals"""
        conn = self.get_db_connection()
        c = conn.cursor()
        
        # Get user preferences
        c.execute("""
            SELECT udp.*, p.age, p.gender, p.weight, p.height, p.bmi
            FROM UserDietPreference udp
            LEFT JOIN Profile p ON udp.user_id = p.user_id
            WHERE udp.user_id = ?
        """, (user_id,))
        
        result = c.fetchone()
        conn.close()
        
        if result:
            return dict(result)
        return None
    
    def load_allergen_map(self):
        conn = self.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT name, allergen_info FROM Ingredient")
        rows = c.fetchall()
        conn.close()
        
        allergen_map = {}
        for name, allergen_info in rows:
            if allergen_info and allergen_info.strip().lower() != "none":
                allergen_map[name.strip()] = allergen_info.strip()
        return allergen_map

    
    def calculate_daily_calories(self, user_prefs):
        """Calculate daily calorie needs based on user profile and goals"""
        try:
            # ✅ Fix: Convert sqlite3.Row to dict if necessary
            if isinstance(user_prefs, sqlite3.Row):
                user_prefs = dict(user_prefs)

            weight = float(user_prefs.get('weight', 70))
            height = float(user_prefs.get('height', 170))
            age = int(user_prefs.get('age', 30))
            gender = user_prefs.get('gender', 'Male').lower()
            goal = user_prefs.get('dietary_goal', 'Weight Loss').lower()

            # BMR and TDEE calculation
            if gender == 'male':
                bmr = 10 * weight + 6.25 * height - 5 * age + 5
            else:
                bmr = 10 * weight + 6.25 * height - 5 * age - 161

            tdee = bmr * 1.55

            # Adjust for goal
            if 'weight loss' in goal or 'lose weight' in goal:
                daily_calories = int(tdee - 500)
            elif 'muscle gain' in goal or 'gain muscle' in goal or 'bulking' in goal:
                daily_calories = int(tdee + 300)
            elif 'maintain' in goal or 'maintenance' in goal:
                daily_calories = int(tdee)
            else:
                daily_calories = int(tdee)

            daily_calories = max(daily_calories, 1200 if gender == 'female' else 1500)
            return daily_calories

        except Exception as e:
            print(f"[calculate_daily_calories ERROR] {e}")
            return 2000

    
    def extract_calories_from_nutrition(self, nutrition_info):
        """Extract calories from nutrition info string"""
        try:
            if not nutrition_info:
                return 0
            
            # Look for calories in format "Calories: 300" or "300 calories"
            calories_match = re.search(r'calories?:?\s*(\d+)', nutrition_info.lower())
            if calories_match:
                return int(calories_match.group(1))
            return 0
        except:
            return 0
    
    def extract_protein_from_nutrition(self, nutrition_info):
        """Extract protein from nutrition info string"""
        try:
            if not nutrition_info:
                return 0
            
            protein_match = re.search(r'protein:?\s*(\d+)', nutrition_info.lower())
            if protein_match:
                return int(protein_match.group(1))
            return 0
        except:
            return 0
    
    def get_suitable_recipes(self, meal_type, calories_per_meal, preferences):
        conn = self.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT * FROM RecipeLibrary")
        rows = c.fetchall()
        conn.close()

        suitable_recipes = []
        allergies = preferences.get('allergies', [])
        dietary_preference = preferences.get('dietary_preference', 'none').lower()

        allergen_map = self.load_allergen_map()

        for row in rows:
            title = row[1]
            ingredients = [i.strip() for i in row[3].split(',')]
            nutrition = json.loads(row[5])
            recipe_calories = nutrition.get("calories", 0)

            # ✅ Check calories range
            calories_ok = abs(recipe_calories - calories_per_meal) <= 400

            # ✅ Check allergens using allergen_map
            allergen_ok = True
            for ingredient in ingredients:
                allergen = allergen_map.get(ingredient)
                if allergen and allergen in allergies:
                    allergen_ok = False
                    break

            # ✅ Diet filtering (optional - simple version)
            diet_ok = True
            if dietary_preference == "vegetarian":
                diet_ok = all(ingredient not in ["Chicken Breast", "Beef", "Turkey Breast", "Salmon", "Cod", "Shrimp"] for ingredient in ingredients)
            elif dietary_preference == "vegan":
                diet_ok = all(ingredient not in ["Chicken Breast", "Beef", "Turkey Breast", "Salmon", "Cod", "Shrimp", "Milk", "Cheese", "Egg", "Greek Yogurt", "Mayonnaise"] for ingredient in ingredients)

            if calories_ok and allergen_ok and diet_ok:
                recipe_dict = dict(row)
                recipe_dict['calories'] = recipe_calories
                suitable_recipes.append(recipe_dict)
            
            if not (calories_ok and allergen_ok and diet_ok):
                print(f"Skipping {title}:")
                if not calories_ok:
                    print(f"  ❌ Calories off target: {recipe_calories} vs {calories_per_meal}")
                if not allergen_ok:
                    print(f"  ❌ Contains allergens: {[allergen_map.get(i) for i in ingredients if allergen_map.get(i) in allergies]}")
                if not diet_ok:
                    print(f"  ❌ Does not meet dietary preference: {dietary_preference}")


        return suitable_recipes


    def create_balanced_meal_plan(self, suitable_recipes, daily_calories, duration_days=7):
        """Create a balanced meal plan for specified duration"""
        meals_per_day = 3  # Breakfast, Lunch, Dinner
        calories_per_meal = daily_calories // meals_per_day
        
        meal_plan = []
        
        # Categorize recipes by meal type (simple categorization)
        breakfast_recipes = []
        lunch_recipes = []
        dinner_recipes = []
        
        for recipe in suitable_recipes:
            title_lower = recipe['title'].lower()
            ingredients_lower = recipe['ingredients'].lower() if 'ingredients' in recipe else ''
            
            # Simple meal categorization
            if any(word in title_lower for word in ['breakfast', 'omelette', 'pancake', 'cereal', 'yogurt', 'parfait']):
                breakfast_recipes.append(recipe)
            elif any(word in title_lower for word in ['salad', 'soup', 'sandwich', 'wrap']):
                lunch_recipes.append(recipe)
            elif any(word in title_lower for word in ['stew', 'pasta', 'rice', 'curry', 'grilled', 'roasted']):
                dinner_recipes.append(recipe)
            else:
                # Default assignment based on calories
                if recipe['calories'] < 300:
                    breakfast_recipes.append(recipe)
                elif recipe['calories'] < 500:
                    lunch_recipes.append(recipe)
                else:
                    dinner_recipes.append(recipe)
        
        # Ensure we have recipes for each meal type
        if not breakfast_recipes:
            breakfast_recipes = [r for r in suitable_recipes if r['calories'] < 400]
        if not lunch_recipes:
            lunch_recipes = [r for r in suitable_recipes if 300 <= r['calories'] <= 600]
        if not dinner_recipes:
            dinner_recipes = [r for r in suitable_recipes if r['calories'] >= 400]
        
        # Generate meal plan
        for day in range(1, duration_days + 1):
            day_meals = []
            
            # Select breakfast
            if breakfast_recipes:
                breakfast = random.choice(breakfast_recipes)
                day_meals.append({
                    'meal_type': 'Breakfast',
                    'recipe': breakfast,
                    'day': day
                })
            
            # Select lunch
            if lunch_recipes:
                lunch = random.choice(lunch_recipes)
                day_meals.append({
                    'meal_type': 'Lunch',
                    'recipe': lunch,
                    'day': day
                })
            
            # Select dinner
            if dinner_recipes:
                dinner = random.choice(dinner_recipes)
                day_meals.append({
                    'meal_type': 'Dinner',
                    'recipe': dinner,
                    'day': day
                })
            
            meal_plan.extend(day_meals)
        
        return meal_plan
    
    def init_diet_plan_tables(self):
        """Initialize diet plan related tables"""
        conn = self.get_db_connection()
        c = conn.cursor()
        
        # Update DietPlan table
        c.execute('''CREATE TABLE IF NOT EXISTS DietPlan
                    (diet_plan_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    plan_name TEXT,
                    description TEXT,
                    daily_calories INTEGER,
                    duration_days INTEGER DEFAULT 7,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status TEXT DEFAULT 'Active',
                    FOREIGN KEY (user_id) REFERENCES User(user_id))''')
        
        # Create MealPlan table
        c.execute('''CREATE TABLE IF NOT EXISTS MealPlan
                    (meal_plan_id TEXT PRIMARY KEY,
                    diet_plan_id TEXT NOT NULL,
                    day_number INTEGER NOT NULL,
                    meal_type TEXT NOT NULL,
                    recipe_id TEXT NOT NULL,
                    serving_size REAL DEFAULT 1.0,
                    calories INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id),
                    FOREIGN KEY (recipe_id) REFERENCES RecipeLibrary(recipe_id))''')
        
        # Create NutritionTargets table
        c.execute('''CREATE TABLE IF NOT EXISTS NutritionTargets
                    (target_id TEXT PRIMARY KEY,
                    diet_plan_id TEXT NOT NULL,
                    daily_calories INTEGER,
                    protein_grams INTEGER,
                    carbs_grams INTEGER,
                    fat_grams INTEGER,
                    fiber_grams INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id))''')
        
        # Create UserDietPlanProgress table
        c.execute('''CREATE TABLE IF NOT EXISTS UserDietPlanProgress
                    (progress_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    diet_plan_id TEXT NOT NULL,
                    date DATE NOT NULL,
                    calories_consumed INTEGER DEFAULT 0,
                    meals_completed INTEGER DEFAULT 0,
                    weight REAL,
                    notes TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES User(user_id),
                    FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id))''')
        
        conn.commit()
        conn.close()


# API Endpoints Functions (to be registered with Flask app)
def setup_diet_plan_routes(app, diet_system):
    """Setup all diet plan routes with the Flask app"""
    
    @app.route('/api/generate-diet-plan', methods=['POST'])
    def generate_diet_plan_route():
        """Generate a personalized diet plan for a user"""
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            duration_days = int(data.get('duration_days', 7))
            plan_name = data.get('plan_name', 'My Diet Plan')
            
            if not user_id:
                return jsonify({'error': 'user_id is required', 'success': False}), 400
            
            # Ensure user_id format
            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"
            
            # Get user dietary preferences
            user_prefs = diet_system.get_user_dietary_preferences(user_id)
            if not user_prefs:
                return jsonify({'error': 'User dietary preferences not found', 'success': False}), 404
            
            # Get ingredient-level dislikes
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            c.execute("""
                SELECT ingredient_id, preference_type 
                FROM DietPreferenceIngredient 
                WHERE diet_pref_id = (
                    SELECT diet_pref_id FROM UserDietPreference 
                    WHERE user_id = ? ORDER BY created_at DESC LIMIT 1
                )
            """, (user_id,))
            ingredient_prefs = {row['ingredient_id']: row['preference_type'] for row in c.fetchall()}
            conn.close()
            user_prefs['ingredient_preferences'] = ingredient_prefs

            # Calculate daily calorie needs
            daily_calories = diet_system.calculate_daily_calories(user_prefs)
            calories_per_meal = daily_calories // 3

            # Get suitable recipes for all meal types
            breakfast_recipes = diet_system.get_suitable_recipes("breakfast", calories_per_meal, user_prefs)
            lunch_recipes = diet_system.get_suitable_recipes("lunch", calories_per_meal, user_prefs)
            dinner_recipes = diet_system.get_suitable_recipes("dinner", calories_per_meal, user_prefs)

            # Combine all suitable recipes
            suitable_recipes = breakfast_recipes + lunch_recipes + dinner_recipes

            
            if not suitable_recipes:
                print("⚠ No recipes matched filters. Adding fallback.")
                conn = diet_system.get_db_connection()  # ✅ Add this
                cursor = conn.cursor()
                cursor.execute("SELECT * FROM RecipeLibrary WHERE recipe_id = 'RCP001'")
                fallback = cursor.fetchone()
                conn.close()  # ✅ Don't forget to close!
                if fallback:
                    suitable_recipes.append(dict(fallback))  # optional: convert Row to dict


            if not suitable_recipes:
                return jsonify({
                    'error': 'Not enough suitable recipes found. Please add more recipes to the database.',
                    'success': False
                }), 400
            
            # Create meal plan
            meal_plan = diet_system.create_balanced_meal_plan(suitable_recipes, daily_calories, duration_days)
            
            # Generate IDs
            diet_plan_id = diet_system.generate_diet_plan_id()
            starting_meal_id = diet_system.generate_meal_plan_id()
            start_num = int(starting_meal_id[2:])

            # Save to database
            conn = diet_system.get_db_connection()
            c = conn.cursor()

            # Mark existing ongoing plan as replaced
            c.execute("""
                SELECT * FROM UserDietPlan 
                WHERE user_id = ? AND status = 'Ongoing'
            """, (user_id,))
            existing_plan = c.fetchone()

            if existing_plan:
                old_diet_plan_id = existing_plan['diet_plan_id']
                
                # Update UserDietPlan status and end_date
                c.execute("""
                    UPDATE UserDietPlan 
                    SET status = 'Replaced', end_date = ?
                    WHERE user_id = ? AND diet_plan_id = ?
                """, (date.today(), user_id, old_diet_plan_id))

                # Update DietPlan status as well
                c.execute("""
                    UPDATE DietPlan 
                    SET status = 'Replaced'
                    WHERE diet_plan_id = ?
                """, (old_diet_plan_id,))

            # Insert into DietPlan
            c.execute("""
                INSERT INTO DietPlan (diet_plan_id, user_id, plan_name, description, daily_calories, duration_days, status)
                VALUES (?, ?, ?, ?, ?, ?, 'Active')
            """, (diet_plan_id, user_id, plan_name, f"Personalized {duration_days}-day diet plan", daily_calories, duration_days))

            # Insert into UserDietPlan
            start_date = date.today()
            end_date = start_date + timedelta(days=duration_days)
            c.execute("""
                INSERT INTO UserDietPlan (user_id, diet_plan_id, start_date, end_date, status)
                VALUES (?, ?, ?, ?, 'Ongoing')
            """, (user_id, diet_plan_id, start_date, end_date))
            
            # Insert meals
            for i, meal in enumerate(meal_plan):
                meal_plan_id = f"MP{start_num + i:03d}"
                c.execute("""
                    INSERT INTO MealPlan (meal_plan_id, diet_plan_id, day_number, meal_type, recipe_id, calories)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (
                    meal_plan_id, diet_plan_id, meal['day'], meal['meal_type'],
                    meal['recipe']['recipe_id'], meal['recipe']['calories']
                ))
            
            # Calculate and save nutrition targets
            target_id = f"NT{diet_plan_id[3:]}"
            protein_target = int(daily_calories * 0.25 / 4)  # 25% of calories from protein
            carbs_target = int(daily_calories * 0.45 / 4)    # 45% of calories from carbs
            fat_target = int(daily_calories * 0.30 / 9)      # 30% of calories from fat
            
            c.execute("""
                INSERT INTO NutritionTargets (target_id, diet_plan_id, daily_calories, protein_grams, carbs_grams, fat_grams, fiber_grams)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (target_id, diet_plan_id, daily_calories, protein_target, carbs_target, fat_target, 25))
            
            conn.commit()
            conn.close()
            
            # Format response
            formatted_plan = defaultdict(list)
            for meal in meal_plan:
                day_key = f"Day {meal['day']}"
                formatted_plan[day_key].append({
                    'meal_type': meal['meal_type'],
                    'recipe': {
                        'recipe_id': meal['recipe']['recipe_id'],
                        'title': meal['recipe']['title'],
                        'description': meal['recipe']['description'],
                        'ingredients': meal['recipe']['ingredients'],
                        'instructions': meal['recipe']['instructions'],
                        'nutrition_info': meal['recipe']['nutrition_info'],
                        'calories': meal['recipe']['calories']
                    }
                })
            
            return jsonify({
                'success': True,
                'diet_plan_id': diet_plan_id,
                'plan_name': plan_name,
                'duration_days': duration_days,
                'daily_calories': daily_calories,
                'nutrition_targets': {
                    'protein_grams': protein_target,
                    'carbs_grams': carbs_target,
                    'fat_grams': fat_target,
                    'fiber_grams': 25
                },
                'meal_plan': dict(formatted_plan),
                'message': f'Diet plan generated successfully for {duration_days} days!'
            }), 201
            
        except Exception as e:
            import traceback
            traceback.print_exc()  # See full traceback in console
            return jsonify({'error': f'Error generating diet plan: {str(e)}', 'success': False}), 500

    @app.route('/api/user-diet-plans/<user_id>', methods=['GET'])
    def get_user_diet_plans_route(user_id):
        """Get all diet plans for a user"""
        try:
            # Ensure user_id format
            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"
            print(f"[DEBUG] Looking up diet plans for user_id: {user_id}")

            
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            c.execute("""
                SELECT dp.*, udp.start_date, udp.end_date, udp.status AS user_status,
                    nt.protein_grams, nt.carbs_grams, nt.fat_grams, nt.fiber_grams
                FROM DietPlan dp
                JOIN UserDietPlan udp ON dp.diet_plan_id = udp.diet_plan_id AND dp.user_id = udp.user_id
                LEFT JOIN NutritionTargets nt ON dp.diet_plan_id = nt.diet_plan_id
                WHERE dp.user_id = ?
                ORDER BY udp.start_date DESC
            """, (user_id,))
            
            plans = []
            for row in c.fetchall():
                plan_dict = dict(row)
                plans.append(plan_dict)
            
            conn.close()
            
            return jsonify({
                'success': True,
                'diet_plans': plans
            })
            
        except Exception as e:
            return jsonify({'error': f'Error retrieving diet plans: {str(e)}', 'success': False}), 500

    @app.route('/api/diet-plan/<diet_plan_id>', methods=['GET'])
    def get_diet_plan_details_route(diet_plan_id):
        """Get detailed diet plan with meal schedule"""
        try:
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            # Get diet plan info
            c.execute("""
            SELECT 
                dp.*, 
                udp.start_date, 
                udp.end_date, 
                udp.status AS user_status, 
                nt.protein_grams, 
                nt.carbs_grams, 
                nt.fat_grams, 
                nt.fiber_grams
            FROM DietPlan dp
            LEFT JOIN NutritionTargets nt ON dp.diet_plan_id = nt.diet_plan_id
            LEFT JOIN UserDietPlan udp ON dp.diet_plan_id = udp.diet_plan_id AND dp.user_id = udp.user_id
            WHERE dp.diet_plan_id = ?
        """, (diet_plan_id,))
            
            plan_info = c.fetchone()
            if not plan_info:
                return jsonify({'error': 'Diet plan not found', 'success': False}), 404
            
            # Get meal plan
            c.execute("""
                SELECT mp.*, r.title, r.description, r.ingredients, r.instructions, r.nutrition_info
                FROM MealPlan mp
                JOIN RecipeLibrary r ON mp.recipe_id = r.recipe_id
                WHERE mp.diet_plan_id = ?
                ORDER BY mp.day_number, mp.meal_type
            """, (diet_plan_id,))
            
            meals = c.fetchall()
            conn.close()
            
            # Format meal plan by day
            meal_plan = defaultdict(list)
            for meal in meals:
                day_key = f"Day {meal['day_number']}"
                meal_plan[day_key].append({
                    'meal_plan_id': meal['meal_plan_id'],
                    'meal_type': meal['meal_type'],
                    'recipe': {
                        'recipe_id': meal['recipe_id'],
                        'title': meal['title'],
                        'description': meal['description'],
                        'ingredients': meal['ingredients'],
                        'instructions': meal['instructions'],
                        'nutrition_info': meal['nutrition_info'],
                        'calories': meal['calories']
                    },
                    'serving_size': meal['serving_size']
                })
            
            return jsonify({
                'success': True,
                'diet_plan': dict(plan_info),
                'meal_plan': dict(meal_plan)
            })
            
        except Exception as e:
            return jsonify({'error': f'Error retrieving diet plan: {str(e)}', 'success': False}), 500

    @app.route('/api/update-diet-preferences', methods=['PUT'])
    def update_diet_preferences_route():
        """Update user's dietary preferences"""
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            
            if not user_id:
                return jsonify({'error': 'user_id is required', 'success': False}), 400
            
            # Ensure user_id format
            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"
            
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            # Check if preferences exist
            c.execute("SELECT diet_pref_id FROM UserDietPreference WHERE user_id = ?", (user_id,))
            existing = c.fetchone()
            
            if existing:
                # Update existing preferences
                update_fields = []
                update_values = []
                
                if 'diet_type' in data:
                    update_fields.append('diet_type = ?')
                    update_values.append(data['diet_type'])
                
                if 'dietary_goal' in data:
                    update_fields.append('dietary_goal = ?')
                    update_values.append(data['dietary_goal'])
                
                if 'allergies' in data:
                    update_fields.append('allergies = ?')
                    update_values.append(data['allergies'])
                
                if 'calories_target' in data:
                    update_fields.append('calories = ?')
                    update_values.append(data['calories_target'])
                
                if update_fields:
                    query = f"UPDATE UserDietPreference SET {', '.join(update_fields)} WHERE user_id = ?"
                    update_values.append(user_id)
                    c.execute(query, update_values)
            else:
                # Create new preferences
                diet_pref_id = diet_system.generate_diet_pref_id()
                c.execute("""
                    INSERT INTO UserDietPreference (diet_pref_id, user_id, diet_type, dietary_goal, allergies, calories)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (diet_pref_id, user_id, data.get('diet_type'), data.get('dietary_goal'), 
                      data.get('allergies'), data.get('calories_target')))
            
            conn.commit()
            conn.close()
            
            return jsonify({
                'success': True,
                'message': 'Dietary preferences updated successfully'
            })
            
        except Exception as e:
            return jsonify({'error': f'Error updating preferences: {str(e)}', 'success': False}), 500

    @app.route('/api/diet-plan-progress', methods=['POST'])
    def log_diet_plan_progress_route():
        """Log user's progress on a diet plan"""
        try:
            data = request.get_json()
            user_id = data.get('user_id')
            diet_plan_id = data.get('diet_plan_id')
            
            if not user_id or not diet_plan_id:
                return jsonify({'error': 'user_id and diet_plan_id are required', 'success': False}), 400
            
            # Ensure user_id format
            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"
            
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            progress_id = f"PG{uuid.uuid4().hex[:8]}"
            current_date = datetime.now().date()
            
            c.execute("""
                INSERT OR REPLACE INTO UserDietPlanProgress 
                (progress_id, user_id, diet_plan_id, date, calories_consumed, meals_completed, weight, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (progress_id, user_id, diet_plan_id, current_date,
                  data.get('calories_consumed', 0), data.get('meals_completed', 0),
                  data.get('weight'), data.get('notes', '')))
            
            conn.commit()
            conn.close()
            
            return jsonify({
                'success': True,
                'message': 'Progress logged successfully',
                'progress_id': progress_id
            })
            
        except Exception as e:
            return jsonify({'error': f'Error logging progress: {str(e)}', 'success': False}), 500

    @app.route('/api/diet-plan/<diet_plan_id>/progress', methods=['GET'])
    def get_diet_plan_progress_route(diet_plan_id):
        """Get progress history for a diet plan"""
        try:
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            c.execute("""
                SELECT * FROM UserDietPlanProgress
                WHERE diet_plan_id = ?
                ORDER BY date DESC
                LIMIT 30
            """, (diet_plan_id,))
            
            progress_data = []
            for row in c.fetchall():
                progress_data.append(dict(row))
            
            conn.close()
            
            return jsonify({
                'success': True,
                'progress_data': progress_data
            })
            
        except Exception as e:
            return jsonify({'error': f'Error retrieving progress: {str(e)}', 'success': False}), 500


# Integration helper function
def integrate_diet_system_with_app(app, get_db_connection_func):
    """
    Helper function to integrate the diet system with your existing Flask app
    
    Usage in your main NextGenFitness.py:
    from diet_plan_system import integrate_diet_system_with_app
    
    # After creating your Flask app and defining get_db_connection
    integrate_diet_system_with_app(app, get_db_connection)
    
    # Also call this in your init_db() function:
    diet_system = DietPlanSystem(get_db_connection)
    diet_system.init_diet_plan_tables()
    """
    
    # Create diet system instance
    diet_system = DietPlanSystem(get_db_connection_func)
    
    # Initialize tables
    diet_system.init_diet_plan_tables()
    
    # Setup routes
    setup_diet_plan_routes(app, diet_system)
    
    return diet_system


