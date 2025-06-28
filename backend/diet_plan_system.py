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
        
    def generate_progress_id(self):
        """
        Generate a unique and sequential progress ID (e.g., PRG001, PRG002).
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            c.execute("SELECT progress_id FROM UserDietPlanProgress ORDER BY progress_id DESC LIMIT 1")
            last_id_row = c.fetchone()
            
            if last_id_row:
                last_id = last_id_row['progress_id']
                # Extract numeric part, convert to int, increment
                numeric_part = int(last_id[3:]) + 1
            else:
                # If no existing progress IDs, start from 1
                numeric_part = 1
            
            # Format to PRG001, PRG002 etc.
            return f'PRG{numeric_part:03d}'
        except Exception as e:
            print(f"Error generating progress ID: {e}")
            # Fallback or re-raise, depending on desired error handling
            # For now, let's just use a UUID as a fallback to prevent blocking
            return f"PRG{int(uuid.uuid4().hex[:8], 16):08d}" 
        finally:
            conn.close()

    def generate_logged_meal_id(self):
        """
        Generate a unique and sequential logged meal ID (e.g., LM001, LM002).
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            c.execute("SELECT meal_id FROM LoggedMeal ORDER BY meal_id DESC LIMIT 1")
            last_id_row = c.fetchone()
            
            if last_id_row:
                last_id = last_id_row['meal_id']
                # Extract numeric part, convert to int, increment
                numeric_part = int(last_id[2:]) + 1
            else:
                # If no existing meal IDs, start from 1
                numeric_part = 1
            
            # Format to LM001, LM002 etc.
            return f'LM{numeric_part:03d}'
        except Exception as e:
            print(f"Error generating logged meal ID: {e}")
            # Fallback or re-raise. Using UUID as fallback to prevent blocking
            return f"LM{uuid.uuid4().hex[:8]}"
        finally:
            conn.close()

    def generate_ingredient_id(self):
        """Generate a unique and sequential ingredient ID (e.g., ING001)."""
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            c.execute("SELECT ingredient_id FROM Ingredient ORDER BY ingredient_id DESC LIMIT 1")
            last_id_row = c.fetchone()
            if last_id_row:
                last_id = last_id_row['ingredient_id']
                numeric_part = int(re.search(r'\d+', last_id).group()) + 1
                return f'ING{numeric_part:03d}'
            else:
                return 'ING001'
        finally:
            conn.close()
    
    def generate_recipe_id(self):
        """Generate a unique and sequential recipe ID (e.g., RCP001)."""
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            c.execute("SELECT recipe_id FROM RecipeLibrary ORDER BY recipe_id DESC LIMIT 1")
            last_id_row = c.fetchone()
            if last_id_row:
                last_id = last_id_row['recipe_id']
                numeric_part = int(re.search(r'\d+', last_id).group()) + 1
                return f'RCP{numeric_part:03d}'
            else:
                return 'RCP001'
        finally:
            conn.close()

    def get_all_ingredients(self):
        conn = self.get_db_connection()
        ingredients = conn.execute('SELECT * FROM Ingredient ORDER BY name').fetchall()
        conn.close()
        return [dict(row) for row in ingredients]
    
    def create_ingredient(self, data):
        conn = self.get_db_connection()
        new_id = self.generate_ingredient_id()
        try:
            conn.execute('''
                INSERT INTO Ingredient (ingredient_id, name, category, nutritional_value, allergen_info)
                VALUES (?, ?, ?, ?, ?)
            ''', (new_id, data['name'], data.get('category'), data.get('nutritional_value'), data.get('allergen_info')))
            conn.commit()
            return {'success': True, 'ingredient_id': new_id}
        except sqlite3.IntegrityError:
             return {'success': False, 'error': 'Ingredient with this name may already exist.'}
        finally:
            conn.close()

    def update_ingredient(self, ingredient_id, data):
        conn = self.get_db_connection()
        try:
            conn.execute('''
                UPDATE Ingredient 
                SET name = ?, category = ?, nutritional_value = ?, allergen_info = ?
                WHERE ingredient_id = ?
            ''', (data['name'], data.get('category'), data.get('nutritional_value'), data.get('allergen_info'), ingredient_id))
            conn.commit()
            return {'success': True}
        finally:
            conn.close()

    def delete_ingredient(self, ingredient_id):
        conn = self.get_db_connection()
        try:
            conn.execute('DELETE FROM Ingredient WHERE ingredient_id = ?', (ingredient_id,))
            conn.commit()
            return {'success': True}
        finally:
            conn.close()

    def get_all_recipes(self):
        conn = self.get_db_connection()
        recipes = conn.execute('SELECT * FROM RecipeLibrary ORDER BY title').fetchall()
        conn.close()
        return [dict(row) for row in recipes]
    
    def create_recipe(self, data):
        conn = self.get_db_connection()
        new_id = self.generate_recipe_id()
        try:
            conn.execute('''
                INSERT INTO RecipeLibrary (recipe_id, title, description, ingredients, instructions, nutrition_info, image_url)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                new_id, data['title'], data.get('description'), data.get('ingredients'),
                data.get('instructions'), data.get('nutrition_info'), data.get('image_url')
            ))
            conn.commit()
            return {'success': True, 'recipe_id': new_id}
        finally:
            conn.close()

    def update_recipe(self, recipe_id, data):
        conn = self.get_db_connection()
        try:
            conn.execute('''
                UPDATE RecipeLibrary
                SET title = ?, description = ?, ingredients = ?, instructions = ?, nutrition_info = ?, image_url = ?
                WHERE recipe_id = ?
            ''', (
                data['title'], data.get('description'), data.get('ingredients'),
                data.get('instructions'), data.get('nutrition_info'), data.get('image_url'), recipe_id
            ))
            conn.commit()
            return {'success': True}
        finally:
            conn.close()
            
    def delete_recipe(self, recipe_id):
        conn = self.get_db_connection()
        try:
            conn.execute('DELETE FROM RecipeLibrary WHERE recipe_id = ?', (recipe_id,))
            conn.commit()
            return {'success': True}
        finally:
            conn.close()
        
    def log_user_meal(self, data):
        """Logs a user's meal and syncs it with their daily progress"""
        try:
            user_id = data['user_id']
            diet_plan_id = data.get('diet_plan_id')
            meal_type = data['meal_type']
            meal_name = data['meal_name']
            calories = float(data['calories'])
            notes = data.get('notes', '')
            log_date = date.today().isoformat()  # Use today's date for logging

            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"

            conn = self.get_db_connection()
            c = conn.cursor()

            # Determine diet_plan_id ---
            diet_plan_id = data.get('diet_plan_id') # Try to get from the request first
            if not diet_plan_id:
                # If not provided by frontend, fetch the user's latest (active) diet plan
                c.execute("SELECT diet_plan_id FROM DietPlan WHERE user_id = ? ORDER BY created_at DESC LIMIT 1", (user_id,))
                latest_diet_plan = c.fetchone()
                if latest_diet_plan:
                    diet_plan_id = latest_diet_plan['diet_plan_id']
                else:
                    # If no diet plan is found, return an error as it's a NOT NULL constraint
                    return {'success': False, 'error': 'No active diet plan found for this user. Please create a diet plan first.'}

            # Ensure there's a progress row for today for the given user and diet_plan
            c.execute("""
                SELECT progress_id, calories_consumed, meals_completed FROM UserDietPlanProgress
                WHERE user_id = ? AND diet_plan_id = ? AND date = ?
            """, (user_id, diet_plan_id, log_date))

            progress = c.fetchone()

            if progress:
                progress_id = progress['progress_id']
                new_calories = progress['calories_consumed'] + calories
                new_meals = progress['meals_completed'] + 1

                c.execute("""
                    UPDATE UserDietPlanProgress
                    SET calories_consumed = ?, meals_completed = ?
                    WHERE progress_id = ?
                """, (new_calories, new_meals, progress_id))
            else:
                progress_id = self.generate_progress_id()
                c.execute("""
                    INSERT INTO UserDietPlanProgress (progress_id, user_id, diet_plan_id, date, calories_consumed, meals_completed)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (progress_id, user_id, diet_plan_id, log_date, calories, 1))

            # Log the meal
            meal_id = self.generate_logged_meal_id()
            c.execute("""
                INSERT INTO LoggedMeal (meal_id, user_id, diet_plan_id, progress_id, meal_type, meal_name, calories, notes)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (meal_id, user_id, diet_plan_id, progress_id, meal_type, meal_name, calories, notes))

            conn.commit()
            conn.close()

            return {
                'success': True,
                'message': 'Meal logged and progress updated successfully',
                'meal_id': meal_id,
                'progress_id': progress_id
            }

        except Exception as e:
            conn.rollback() # Important: Rollback on error
            print(f"Error logging meal: {e}") # Print error for debugging
            return {'success': False, 'error': str(e)}
        
    def _update_daily_progress(self, user_id, log_date):
        """
        Recalculates total calories for a given user and date,
        and updates UserDietPlanProgress.
        log_date should be in 'YYYY-MM-DD' format.
        """
        conn = self.get_db_connection()
        c = conn.cursor()

        try:
            # Calculate total calories from all meals logged for this user on this date
            c.execute("""
                SELECT SUM(calories) AS total_calories, COUNT(meal_id) AS total_meals
                FROM LoggedMeal
                WHERE user_id = ? AND date(created_at) = ?
            """, (user_id, log_date))
            
            result = c.fetchone()
            new_total_calories = result['total_calories'] if result and result['total_calories'] is not None else 0
            new_total_meals = result['total_meals'] if result and result['total_meals'] is not None else 0

            # Get or create progress entry for the date
            c.execute("SELECT progress_id FROM UserDietPlanProgress WHERE user_id = ? AND date = ?",
                      (user_id, log_date))
            progress_entry = c.fetchone()

            if progress_entry:
                # Update existing progress entry
                c.execute("""
                    UPDATE UserDietPlanProgress
                    SET calories_consumed = ?, meals_completed = ?
                    WHERE progress_id = ?
                """, (new_total_calories, new_total_meals, progress_entry['progress_id']))
                print(f"Updated progress for {user_id} on {log_date} to {new_total_calories} calories.")
            else:
                # This should ideally not happen if meals are logged correctly,
                # but handle if a meal is added to a day without a progress record.
                # Find an existing diet plan for the user or default
                c.execute("SELECT diet_plan_id FROM DietPlan WHERE user_id = ? ORDER BY created_at DESC LIMIT 1", (user_id,))
                diet_plan_id_row = c.fetchone()
                
                if not diet_plan_id_row:
                    raise Exception("No active diet plan found for user. Cannot update progress.")
                
                diet_plan_id = diet_plan_id_row['diet_plan_id']
                progress_id = self.generate_progress_id()

                c.execute("""
                    INSERT INTO UserDietPlanProgress (progress_id, user_id, diet_plan_id, date, calories_consumed, meals_completed)
                    VALUES (?, ?, ?, ?, ?, ?)
                """, (progress_id, user_id, diet_plan_id, log_date, new_total_calories, new_total_meals))
                print(f"Created new progress entry for {user_id} on {log_date} with {new_total_calories} calories and {new_total_meals} meals.")

            conn.commit()
            return True
        except Exception as e:
            conn.rollback()
            print(f"Error updating daily progress for {user_id} on {log_date}: {e}")
            raise # Re-raise the exception to be caught by the route handler
        finally:
            conn.close()

    def delete_logged_meal(self, meal_id):
        """
        Deletes a logged meal entry and updates daily progress.
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            # Get meal details before deleting to update progress
            c.execute("SELECT user_id, date(created_at) AS log_date FROM LoggedMeal WHERE meal_id = ?", (meal_id,))
            meal_info = c.fetchone()

            if not meal_info:
                return {'success': False, 'error': 'Meal not found.'}

            user_id = meal_info['user_id']
            log_date = meal_info['log_date']

            c.execute("DELETE FROM LoggedMeal WHERE meal_id = ?", (meal_id,))
            conn.commit()

            # Now, update the user's daily progress for that date
            self._update_daily_progress(user_id, log_date)

            return {'success': True, 'message': 'Meal deleted successfully.'}
        except Exception as e:
            conn.rollback()
            print(f"Error deleting meal {meal_id}: {e}")
            return {'success': False, 'error': f'Failed to delete meal: {str(e)}'}
        finally:
            conn.close()

    def update_logged_meal(self, meal_id, updated_data):
        """
        Updates an existing logged meal entry and recalculates daily progress.
        updated_data can contain meal_type, meal_name, calories, notes.
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            # Get original meal info to determine if date changed (unlikely with this UI but good to get)
            # and to get user_id and old_calories for progress update context
            c.execute("SELECT user_id, calories, date(created_at) AS log_date FROM LoggedMeal WHERE meal_id = ?", (meal_id,))
            original_meal_info = c.fetchone()

            if not original_meal_info:
                return {'success': False, 'error': 'Meal not found.'}

            user_id = original_meal_info['user_id']
            original_log_date = original_meal_info['log_date']

            # Build update query dynamically
            set_clauses = []
            values = []
            
            if 'meal_type' in updated_data:
                set_clauses.append("meal_type = ?")
                values.append(updated_data['meal_type'])
            if 'meal_name' in updated_data:
                set_clauses.append("meal_name = ?")
                values.append(updated_data['meal_name'])
            if 'calories' in updated_data:
                set_clauses.append("calories = ?")
                values.append(updated_data['calories'])
            if 'notes' in updated_data:
                set_clauses.append("notes = ?")
                values.append(updated_data['notes'])
            
            if not set_clauses:
                return {'success': False, 'error': 'No fields to update provided.'}

            query = f"UPDATE LoggedMeal SET {', '.join(set_clauses)} WHERE meal_id = ?"
            values.append(meal_id)

            c.execute(query, tuple(values))
            conn.commit()

            # Recalculate and update the user's daily progress for the original date
            self._update_daily_progress(user_id, original_log_date)

            return {'success': True, 'message': 'Meal updated successfully.'}
        except Exception as e:
            conn.rollback()
            print(f"Error updating meal {meal_id}: {e}")
            return {'success': False, 'error': f'Failed to update meal: {str(e)}'}
        finally:
            conn.close()

    def get_user_progress_for_date(self, user_id, target_date):
        """
        Retrieves a user's diet plan progress for a specific date.
        target_date should be in 'YYYY-MM-DD' format.
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        try:
            c.execute("""
                SELECT
                    progress_id,
                    user_id,
                    diet_plan_id,
                    date,
                    calories_consumed,
                    meals_completed,
                    weight,
                    notes,
                    created_at
                FROM UserDietPlanProgress
                WHERE user_id = ? AND date = ?
            """, (user_id, target_date))
            
            progress_data = c.fetchone()
            
            if progress_data:
                return {'success': True, 'progress': dict(progress_data)}
            else:
                return {
                'success': True,
                'progress': {
                    'user_id': user_id,
                    'date': target_date,
                    'calories_consumed': 0,
                    'meals_completed': 0,
                    'weight': None,
                    'notes': '',
                    'diet_plan_id': None,
                    'progress_id': None,
                    'created_at': None
                }
            }
        except sqlite3.Error as e:
            return {'success': False, 'error': f'Database error: {str(e)}'}
        except Exception as e:
            return {'success': False, 'error': f'An unexpected error occurred: {str(e)}'}
        finally:
            conn.close()

    def get_user_diet_summary(self, user_id):
        """
        Retrieves a comprehensive summary of the user's active diet plan progress.
        Includes plan details, overall progress, and last logged meal.
        """
        conn = self.get_db_connection()
        c = conn.cursor()
        
        try:
            summary = {
                'active_plan': None,
                'overall_progress': {
                    'total_days_completed': 0,
                    'total_calories_consumed': 0,
                    'total_planned_calories': 0,
                    'average_daily_calories_consumed': 0,
                    'average_daily_calories_planned': 0,
                    'completion_percentage': 0,
                    'current_day_of_plan': 0
                },
                'last_logged_meal': None
            }

            # 1. Get Active Diet Plan Details
            c.execute("""
                SELECT diet_plan_id, plan_name, start_date, end_date, daily_calories, duration_days
                FROM DietPlan
                WHERE user_id = ? AND status = 'Active'
                ORDER BY created_at DESC LIMIT 1
            """, (user_id,))
            active_plan = c.fetchone()

            if active_plan:
                summary['active_plan'] = dict(active_plan)
                
                # Calculate current day of plan
                start_date_obj = datetime.strptime(active_plan['start_date'], '%Y-%m-%d').date()
                today = date.today()
                
                # Ensure today is not before start_date, if it is, set day 0 or 1
                if today < start_date_obj:
                    summary['overall_progress']['current_day_of_plan'] = 0 # Plan hasn't started yet
                else:
                    summary['overall_progress']['current_day_of_plan'] = (today - start_date_obj).days + 1

                # 2. Get Overall Progress
                # Sum calories and count days with progress for the *active plan's duration*
                c.execute("""
                    SELECT SUM(calories_consumed) AS total_consumed, 
                           COUNT(DISTINCT date) AS distinct_days_logged
                    FROM UserDietPlanProgress
                    WHERE user_id = ? AND diet_plan_id = ? AND date <= ?
                """, (user_id, active_plan['diet_plan_id'], today.isoformat()))
                
                overall_progress = c.fetchone()
                
                if overall_progress:
                    total_consumed = overall_progress['total_consumed'] if overall_progress['total_consumed'] is not None else 0
                    distinct_days_logged = overall_progress['distinct_days_logged'] if overall_progress['distinct_days_logged'] is not None else 0
                    
                    summary['overall_progress']['total_calories_consumed'] = total_consumed
                    summary['overall_progress']['total_days_completed'] = distinct_days_logged

                    if distinct_days_logged > 0:
                        summary['overall_progress']['average_daily_calories_consumed'] = round(total_consumed / distinct_days_logged, 2)
                    
                    summary['overall_progress']['average_daily_calories_planned'] = active_plan['daily_calories']

                    # Completion Percentage: Based on days elapsed vs total duration
                    total_plan_days = active_plan['duration_days']
                    if total_plan_days > 0:
                        # Use days elapsed, up to total_plan_days, for percentage
                        days_elapsed_for_percent = min(summary['overall_progress']['current_day_of_plan'], total_plan_days)
                        summary['overall_progress']['completion_percentage'] = round((days_elapsed_for_percent / total_plan_days) * 100, 2)
            
            # 3. Get Last Logged Meal
            c.execute("""
                SELECT meal_id, meal_type, meal_name, calories, notes, created_at
                FROM LoggedMeal
                WHERE user_id = ?
                ORDER BY created_at DESC LIMIT 1
            """, (user_id,))
            last_meal = c.fetchone()
            if last_meal:
                summary['last_logged_meal'] = dict(last_meal)

            return {'success': True, 'summary': summary}

        except sqlite3.Error as e:
            print(f"Database error fetching diet summary: {e}")
            return {'success': False, 'error': f'Database error: {str(e)}'}
        except Exception as e:
            print(f"An unexpected error occurred fetching diet summary: {e}")
            return {'success': False, 'error': f'An unexpected error occurred: {str(e)}'}
        finally:
            conn.close()
    
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
    
    def is_diet_compatible(self, ingredients, dietary_preference, fitness_goal=None, recipe_nutrition=None):
        """Check if recipe is compatible with dietary and fitness goals"""
        restricted_ingredients = {
            'vegetarian': {"chicken breast", "beef", "turkey breast", "salmon", "cod", "shrimp"},
            'vegan': {"chicken breast", "beef", "turkey breast", "salmon", "cod", "shrimp",
                    "milk", "cheese", "egg", "greek yogurt", "mayonnaise", "butter", "yogurt"},
            'pescatarian': {"chicken breast", "beef", "turkey breast"},
            'halal': {"pork", "bacon", "ham", "lard", "gelatin (non-halal)"},
            'kosher': {"pork", "shellfish", "shrimp", "bacon", "ham", "lobster"}
        }

        # Normalize ingredients
        restricted = restricted_ingredients.get(dietary_preference.lower(), set())
        for ingredient in ingredients:
            normalized = ingredient.strip().lower()
            if normalized in restricted:
                return False

        # Optional: Fitness goal filtering based on macros
        if recipe_nutrition and fitness_goal:
            cal = recipe_nutrition.get('calories', 0)
            protein = recipe_nutrition.get('protein', 0)

            if fitness_goal == "weight loss" and cal > 600:
                return False  # skip high-calorie meals
            elif fitness_goal == "muscle gain" and protein < 20:
                return False  # skip low-protein meals
            elif fitness_goal == "maintenance" and cal > 800:
                return False

        return True

    
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
        fitness_goal = preferences.get('dietary_goal', 'maintenance').lower()
        ingredient_preferences = preferences.get('ingredient_preferences', {})

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

            # ✅ Check diet compatibility
            diet_ok = self.is_diet_compatible(ingredients, dietary_preference, fitness_goal, nutrition)


            # ✅ Check ingredient dislikes
            ingredient_ok = True
            for ingredient in ingredients:
                pref = ingredient_preferences.get(ingredient.lower())
                if pref and pref.lower() == 'dislike':
                    ingredient_ok = False
                    break

            # # ✅ Diet filtering (optional - simple version)
            # diet_ok = True
            # if dietary_preference == "vegetarian":
            #     diet_ok = all(ingredient not in ["Chicken Breast", "Beef", "Turkey Breast", "Salmon", "Cod", "Shrimp"] for ingredient in ingredients)
            # elif dietary_preference == "vegan":
            #     diet_ok = all(ingredient not in ["Chicken Breast", "Beef", "Turkey Breast", "Salmon", "Cod", "Shrimp", "Milk", "Cheese", "Egg", "Greek Yogurt", "Mayonnaise"] for ingredient in ingredients)

            if calories_ok and allergen_ok and diet_ok and ingredient_ok:
                recipe_dict = dict(row)
                recipe_dict['calories'] = recipe_calories
                suitable_recipes.append(recipe_dict)
            else:
                print(f"Skipping {title}:")
                if not calories_ok:
                    print(f"  ❌ Calories off target: {recipe_calories} vs {calories_per_meal}")
                if not allergen_ok:
                    print(f"  ❌ Contains allergens: {[allergen_map.get(i) for i in ingredients if allergen_map.get(i) in allergies]}")
                if not diet_ok:
                    print(f"  ❌ Does not meet dietary preference: {dietary_preference}")
                if not ingredient_ok:
                    print(f"  ❌ Contains disliked ingredients: {[i for i in ingredients if ingredient_preferences.get(i.lower()) == 'dislike']}")

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
            
            # Enhanced meal categorization using title and ingredients
            if any(word in title_lower for word in [
                'breakfast', 'omelette', 'pancake', 'cereal', 'yogurt', 'parfait',
                'toast', 'scramble', 'oatmeal', 'oats', 'banana', 'muffin', 'smoothie',
                'burrito', 'walnut', 'honey', 'wrap', 'egg salad']):
                breakfast_recipes.append(recipe)

            elif any(word in title_lower for word in [
                'salad', 'soup', 'sandwich', 'wrap', 'bowl', 'quinoa', 'stir fry', 'lentil']):
                lunch_recipes.append(recipe)

            elif any(word in title_lower for word in [
                'stew', 'pasta', 'rice', 'curry', 'grilled', 'roasted', 'dinner',
                'alfredo', 'risotto', 'stuffed', 'baked', 'parmesan']):
                dinner_recipes.append(recipe)

            else:
                # Use calorie-based fallback
                calories = recipe.get('calories', 0)
                if calories < 300:
                    breakfast_recipes.append(recipe)
                elif calories < 500:
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
                    start_date DATE,
                    end_date DATE,
                    daily_calories INTEGER,
                    protein_grams INTEGER,
                    carbs_grams INTEGER,
                    fat_grams INTEGER,
                    fiber_grams INTEGER,
                    duration_days INTEGER DEFAULT 7,
                    status TEXT DEFAULT 'Active',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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

        # Create LoggedMeal table
        c.execute('''CREATE TABLE IF NOT EXISTS LoggedMeal (
                        meal_id TEXT PRIMARY KEY,
                        user_id TEXT NOT NULL,
                        diet_plan_id TEXT,
                        progress_id TEXT,
                        meal_type TEXT NOT NULL,
                        meal_name TEXT NOT NULL,
                        calories REAL NOT NULL,
                        notes TEXT,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        FOREIGN KEY (user_id) REFERENCES User(user_id),
                        FOREIGN KEY (diet_plan_id) REFERENCES DietPlan(diet_plan_id),
                        FOREIGN KEY (progress_id) REFERENCES UserDietPlanProgress(progress_id)
                    );''')
        
        # Create UserDietPreference table
        c.execute('''CREATE TABLE IF NOT EXISTS UserDietPreference
                    (diet_pref_id TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    diet_type TEXT,
                    dietary_goal TEXT,
                    allergies TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES User(user_id))''')

        # Create Ingredient table
        c.execute('''CREATE TABLE IF NOT EXISTS Ingredient (
                    ingredient_id TEXT PRIMARY KEY,
                    name TEXT NOT NULL UNIQUE,
                    category TEXT,
                    nutritional_value TEXT,
                    allergen_info TEXT)''')

        # Create RecipeLibrary table
        c.execute('''CREATE TABLE IF NOT EXISTS RecipeLibrary (
                    recipe_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT,
                    ingredients TEXT,
                    instructions TEXT,
                    nutrition_info TEXT,
                    image_url TEXT)''')
        
        # Create DietPreferenceIngredient table
        c.execute('''CREATE TABLE IF NOT EXISTS DietPreferenceIngredient (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    diet_pref_id TEXT NOT NULL,
                    ingredient_id TEXT NOT NULL,
                    preference_type TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (diet_pref_id) REFERENCES UserDietPreference(diet_pref_id),
                    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(ingredient_id))''')
        
        # Indexes for performance
        c.execute('CREATE INDEX IF NOT EXISTS idx_diet_plan_user ON DietPlan(user_id)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_meal_plan_diet ON MealPlan(diet_plan_id)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_progress_user_date ON UserDietPlanProgress(user_id, date)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_progress_diet_plan ON UserDietPlanProgress(diet_plan_id)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_diet_pref_user ON UserDietPreference(user_id)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_recipe_title ON RecipeLibrary(title)')
        c.execute('CREATE INDEX IF NOT EXISTS idx_logged_meal_user ON LoggedMeal(user_id)')
        
        conn.commit()
        conn.close()
    


# API Endpoints Functions (to be registered with Flask app)
def setup_diet_plan_routes(app, diet_system):
    """Setup all diet plan routes with the Flask app"""
    
    @app.route('/api/admin/ingredients', methods=['GET', 'POST'])
    def admin_ingredients():
        if request.method == 'GET':
            ingredients = diet_system.get_all_ingredients()
            return jsonify(ingredients)
        elif request.method == 'POST':
            data = request.json
            result = diet_system.create_ingredient(data)
            return jsonify(result), 201 if result['success'] else 400

    @app.route('/api/admin/ingredients/<ingredient_id>', methods=['PUT', 'DELETE'])
    def admin_ingredient_detail(ingredient_id):
        if request.method == 'PUT':
            data = request.json
            result = diet_system.update_ingredient(ingredient_id, data)
            return jsonify(result)
        elif request.method == 'DELETE':
            result = diet_system.delete_ingredient(ingredient_id)
            return jsonify(result)

    @app.route('/api/admin/recipes', methods=['GET', 'POST'])
    def admin_recipes():
        if request.method == 'GET':
            recipes = diet_system.get_all_recipes()
            return jsonify(recipes)
        elif request.method == 'POST':
            data = request.json
            result = diet_system.create_recipe(data)
            return jsonify(result), 201 if result['success'] else 400

    @app.route('/api/admin/recipes/<recipe_id>', methods=['PUT', 'DELETE'])
    def admin_recipe_detail(recipe_id):
        if request.method == 'PUT':
            data = request.json
            result = diet_system.update_recipe(recipe_id, data)
            return jsonify(result)
        elif request.method == 'DELETE':
            result = diet_system.delete_recipe(recipe_id)
            return jsonify(result)

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
                SELECT * FROM DietPlan 
                WHERE user_id = ? AND status = 'Active'
            """, (user_id,))
            existing_plan = c.fetchone()

            if existing_plan:
                old_diet_plan_id = existing_plan['diet_plan_id']
                
                # Update DietPlan status and end_date
                c.execute("""
                    UPDATE DietPlan 
                    SET status = 'Archived', end_date = ?
                    WHERE user_id = ? AND diet_plan_id = ?
                """, (date.today(), user_id, old_diet_plan_id))

                # # Update DietPlan status as well
                # c.execute("""
                #     UPDATE DietPlan 
                #     SET status = 'Replaced'
                #     WHERE diet_plan_id = ?
                # """, (old_diet_plan_id,))

            # Determine plan name and description based on dietary preferences
            goal = user_prefs.get('dietary_goal', 'Healthy Lifestyle')
            diet_type = user_prefs.get('dietary_preference', 'General')

            # Customize plan name
            plan_name = f"{diet_type.title()} - {goal.title()} Plan"

            # Customize description
            description = f"A personalized {duration_days}-day diet plan for a {diet_type.lower()} diet with goal: {goal.lower()}."

            start_date = date.today()
            end_date = start_date + timedelta(days=duration_days)

            protein_target = int(daily_calories * 0.25 / 4)  # 25% of calories from protein
            carbs_target = int(daily_calories * 0.45 / 4)    # 45% of calories from carbs
            fat_target = int(daily_calories * 0.30 / 9)      # 30% of calories from fat

            # Insert into DietPlan
            c.execute("""
                INSERT INTO DietPlan (diet_plan_id, user_id, plan_name, description, start_date, end_date, daily_calories, protein_grams, carbs_grams, fat_grams, fiber_grams, duration_days, status, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (diet_plan_id, user_id, plan_name, description, start_date, end_date, daily_calories, protein_target, carbs_target, fat_target, 25, duration_days, 'Active', date.today()))

            # # Insert into UserDietPlan
            # start_date = date.today()
            # end_date = start_date + timedelta(days=duration_days)
            # c.execute("""
            #     INSERT INTO UserDietPlan (user_id, diet_plan_id, start_date, end_date, status)
            #     VALUES (?, ?, ?, ?, 'Ongoing')
            # """, (user_id, diet_plan_id, start_date, end_date))
            
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
            
            # c.execute("""
            #     INSERT INTO NutritionTargets (target_id, diet_plan_id, daily_calories, protein_grams, carbs_grams, fat_grams, fiber_grams)
            #     VALUES (?, ?, ?, ?, ?, ?, ?)
            # """, (target_id, diet_plan_id, daily_calories, protein_target, carbs_target, fat_target, 25))
            
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
                SELECT 
                    diet_plan_id,
                    user_id,
                    plan_name,
                    description,
                    start_date,
                    end_date,
                    daily_calories,
                    protein_grams,
                    carbs_grams,
                    fat_grams,
                    fiber_grams,
                    duration_days,
                    status AS user_status,
                    created_at
                FROM DietPlan
                WHERE user_id = ?
                ORDER BY start_date DESC
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
                    diet_plan_id,
                    user_id,
                    plan_name,
                    description,
                    start_date,
                    end_date,
                    status AS user_status,
                    daily_calories,
                    protein_grams,
                    carbs_grams,
                    fat_grams,
                    fiber_grams,
                    duration_days,
                    created_at
                FROM DietPlan
                WHERE diet_plan_id = ?
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
                diet_pref_id = existing['diet_pref_id']
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
                    INSERT INTO UserDietPreference (diet_pref_id, user_id, diet_type, dietary_goal, allergies)
                    VALUES (?, ?, ?, ?, ?)
                """, (diet_pref_id, user_id, data.get('diet_type'), data.get('dietary_goal'), 
                      data.get('allergies')))
            # --- Merge: Clear old ingredient preferences and insert new ones ---
            c.execute("DELETE FROM DietPreferenceIngredient WHERE diet_pref_id = ?", (diet_pref_id,))
            ingredient_prefs = data.get('ingredient_preferences', [])  # Expecting a list of dicts
            for pref in ingredient_prefs:
                ingredient_name = pref.get('ingredient_name')
                preference_type = pref.get('preference_type')

                # Look up ingredient_id by name
                c.execute("SELECT ingredient_id FROM Ingredient WHERE LOWER(name) = LOWER(?)", (ingredient_name,))
                row = c.fetchone()

                if not row:
                    raise ValueError(f"Ingredient not found: {ingredient_name}")

                ingredient_id = row['ingredient_id']

                # Insert into DietPreferenceIngredient
                c.execute("""
                    INSERT INTO DietPreferenceIngredient (diet_pref_id, ingredient_id, preference_type)
                    VALUES (?, ?, ?)
                """, (diet_pref_id, ingredient_id, preference_type))
            # --- End merge ---

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

            progress_id = self.generate_progress_id()
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
    
    @app.route('/api/ingredients', methods=['GET'])
    def get_ingredient_names():
        """Return a list of all ingredient names for suggestions"""
        try:
            conn = diet_system.get_db_connection()
            c = conn.cursor()

            c.execute("SELECT name FROM Ingredient ORDER BY name ASC")
            rows = c.fetchall()

            ingredient_names = [row['name'] for row in rows]

            conn.close()
            return jsonify(ingredient_names), 200

        except Exception as e:
            return jsonify({'error': f'Failed to fetch ingredients: {str(e)}'}), 500
        
    @app.route('/api/meal-name-suggestions/<query>', methods=['GET'])
    def get_meal_name_suggestions(query):
        """Return a list of recipe title suggestions from RecipeLibrary based on user input"""
        try:
            conn = diet_system.get_db_connection()
            c = conn.cursor()
            
            c.execute("""
                SELECT DISTINCT title
                FROM RecipeLibrary
                WHERE LOWER(title) LIKE ?
                ORDER BY title ASC
                LIMIT 10
            """, (f"%{query.lower()}%",))

            suggestions = [row['title'] for row in c.fetchall()]
            
            conn.close()
            return jsonify(suggestions), 200
        
        except Exception as e:
            return jsonify({'error': f'Failed to fetch recipe suggestions: {str(e)}'}), 500
        
    @app.route('/api/recipe-details', methods=['GET'])
    def get_recipe_details():
        title = request.args.get('title')
        if not title:
            return jsonify({'error': 'Missing title'}), 400

        conn = diet_system.get_db_connection()
        c = conn.cursor()
        c.execute("SELECT nutrition_info FROM RecipeLibrary WHERE LOWER(title) = LOWER(?)", (title.lower(),))
        row = c.fetchone()
        conn.close()

        if not row:
            return jsonify({'error': 'Recipe not found'}), 404

        nutrition = json.loads(row['nutrition_info']) if row['nutrition_info'] else {}
        return jsonify({
            'calories': nutrition.get('calories', 0)
        }), 200

        
    @app.route('/api/log-meal', methods=['POST'])
    def log_meal_route():
        """API route to log a user meal"""
        data = request.get_json()
        result = diet_system.log_user_meal(data)
        return jsonify(result), 200 if result.get('success') else 500

    @app.route('/api/logged-meals/<user_id>', methods=['GET'])
    def get_logged_meals_route(user_id):
        """Get user's logged meal history, grouped by date"""
        try:
            # Normalize user_id: handle int or string
            if isinstance(user_id, int) or (isinstance(user_id, str) and user_id.isdigit()):
                user_id = f"U{int(user_id):03d}"

            conn = diet_system.get_db_connection()
            c = conn.cursor()

            # c.execute("""
            #     SELECT meal_id, lm.diet_plan_id, meal_type, meal_name, calories, lm.notes, lm.created_at, date(lp.date) AS log_date
            #     FROM LoggedMeal lm
            #     LEFT JOIN UserDietPlanProgress lp ON lm.progress_id = lp.progress_id
            #     WHERE lm.user_id = ?
            #     ORDER BY log_date DESC, lm.created_at DESC
            # """, (user_id,))

            c.execute("""
            SELECT meal_id, diet_plan_id, meal_type, meal_name, calories, notes, created_at
            FROM LoggedMeal
            WHERE user_id = ?
            ORDER BY created_at DESC
        """, (user_id,))

            rows = c.fetchall()
            conn.close()

            # Group by date
            history = {}
            for row in rows:
                raw_created_at = row['created_at']
            
                dt_object = None
                try:
                    # Try parsing with milliseconds first
                    dt_object = datetime.strptime(raw_created_at, '%Y-%m-%d %H:%M:%S.%f')
                except ValueError:
                    try:
                        # If that fails, try parsing without milliseconds
                        dt_object = datetime.strptime(raw_created_at, '%Y-%m-%d %H:%M:%S')
                    except ValueError:
                        print(f"ERROR: Could not parse datetime string: {raw_created_at}")
                        continue # Skip this row if it cannot be parsed

                if dt_object: # Only proceed if parsing was successful
                    # Use the date part of the actual meal creation timestamp for grouping
                    log_date = dt_object.date().isoformat()

                    if log_date not in history:
                        history[log_date] = []

                    history[log_date].append({
                        'meal_id': row['meal_id'],
                        'diet_plan_id': row['diet_plan_id'],
                        'meal_type': row['meal_type'],
                        'meal_name': row['meal_name'],
                        'calories': row['calories'],
                        'notes': row['notes'],
                        'logged_at': raw_created_at
                    })

            return jsonify({
                'success': True,
                'logged_meals': history
            })

        except Exception as e:
            print(f"Error fetching logged meals: {e}")
            return jsonify({'success': False, 'error': f'Failed to fetch logged meals: {str(e)}'}), 500

    @app.route('/api/logged-meal/<meal_id>', methods=['DELETE'])
    def delete_meal_route(meal_id):
        """API route to delete a user meal"""
        result = diet_system.delete_logged_meal(meal_id)
        return jsonify(result), 200 if result.get('success') else 500

    @app.route('/api/logged-meal/<meal_id>', methods=['PUT'])
    def update_meal_route(meal_id):
        """API route to update a user meal"""
        data = request.get_json()
        result = diet_system.update_logged_meal(meal_id, data)
        return jsonify(result), 200 if result.get('success') else 500
    
    @app.route('/api/user-progress/<user_id>/<date>', methods=['GET'])
    def get_user_progress_by_date_route(user_id, date):
        """Get user's diet plan progress for a specific date."""
        try:
            # Normalize user_id: handle int or string
            if isinstance(user_id, int) or (isinstance(user_id, str) and user_id.isdigit()):
                user_id = f"U{int(user_id):03d}"

            # Validate date format (optional but recommended)
            try:
                datetime.strptime(date, '%Y-%m-%d')
            except ValueError:
                return jsonify({'success': False, 'error': 'Invalid date format. Use YYYY-MM-DD.'}), 400

            result = diet_system.get_user_progress_for_date(user_id, date)
            return jsonify(result), 200 if result.get('success') else 500

        except Exception as e:
            print(f"Error fetching user progress by date: {e}")
            return jsonify({'success': False, 'error': f'Failed to fetch user progress: {str(e)}'}), 500
        
    @app.route('/api/user-diet-summary/<user_id>', methods=['GET'])
    def get_user_diet_summary_route(user_id):
        """Get user's diet plan summary."""
        try:
            if user_id.isdigit():
                user_id = f"U{int(user_id):03d}"
            
            result = diet_system.get_user_diet_summary(user_id)
            return jsonify(result), 200 if result.get('success') else 500
        except Exception as e:
            print(f"Error fetching diet summary: {e}")
            return jsonify({'success': False, 'error': f'Failed to fetch diet summary: {str(e)}'}), 500



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


