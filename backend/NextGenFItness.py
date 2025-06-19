from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import sqlite3
import base64
import json
import uuid
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
import io
from PIL import Image
import requests
import os
from food_recognition import FoodRecognition
import os
import google.generativeai as genai

GOOGLE_API_KEY= 'AIzaSyD5Ilz_JtzhJW_aZup7xBFZs9cOzyW_G6M'
genai.configure(api_key=GOOGLE_API_KEY)

# Initialize Clarifai food recognition
food_recognizer = FoodRecognition('5deb6d79da89437a81b87a21accd1440')

# Configuration for meal scanner
UPLOAD_FOLDER = './backend/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}
MAX_FILE_SIZE = 16 * 1024 * 1024  # 16MB max file size

# Ensure upload directory exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def validate_image(file_path):
    """Validate that the uploaded file is a valid image"""
    try:
        with Image.open(file_path) as img:
            img.verify()
        return True
    except Exception:
        return False

# Initialize Flask app with configurations
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE
CORS(app)

# Error handlers
@app.errorhandler(413)
def too_large(e):
    return jsonify({'error': 'File too large', 'success': False}), 413

@app.errorhandler(400)
def bad_request(e):
    return jsonify({'error': 'Bad request', 'success': False}), 400

@app.errorhandler(500)
def internal_error(e):
    return jsonify({'error': 'Internal server error', 'success': False}), 500

def get_db_connection():
    conn = sqlite3.connect('./backend/NextGenFitness.db')
    return conn

def init_db():
    conn = get_db_connection()
    c = conn.cursor()
    
    # Create User table
    c.execute('''CREATE TABLE IF NOT EXISTS User
                (user_id Text,
                username TEXT, 
                email Text Unique,
                password TEXT,
                role INTEGER)''')

    # Create MealScans table
    c.execute('''CREATE TABLE IF NOT EXISTS MealScans
                (meal_scan_id TEXT PRIMARY KEY,
                user_id TEXT,
                food_name TEXT,
                calories INTEGER,
                nutrients TEXT,
                image_path TEXT,
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES User(user_id))''')
                
    conn.commit()
    conn.close()

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = generate_password_hash(data.get('password'))
    role = int(data.get('role', 1))

    conn = get_db_connection()
    c = conn.cursor()

    # Check if username exists
    c.execute("SELECT * FROM User WHERE username = ?", (username,))
    if c.fetchone():
        conn.close()
        return jsonify({'error': 'Username already exists'}), 409

    # Check if email exists
    c.execute("SELECT * FROM User WHERE email = ?", (email,))
    if c.fetchone():
        conn.close()
        return jsonify({'error': 'Email already registered'}), 409

    # Generate new user_id
    c.execute("SELECT user_id FROM User ORDER BY user_id DESC LIMIT 1")
    last = c.fetchone()
    if last and last[0]:
        last_num = int(last[0][1:])  # Remove 'U' and convert to int
        new_num = last_num + 1
    else:
        new_num = 1
    new_user_id = f"U{new_num:03d}"

    # Insert user
    c.execute("INSERT INTO User (user_id, username, email, password, role) VALUES (?, ?, ?, ?, ?)",
              (new_user_id, username, email, password, role))
    conn.commit()
    conn.close()

    return jsonify({'message': 'User registered successfully', 'user_id': new_user_id}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT user_id, password FROM User WHERE username = ?", (username,))
    user = c.fetchone()
    conn.close()

    if user and check_password_hash(user[1], password):
        return jsonify({'message': 'Login successful', 'user_id': user[0]}), 200
    else:
        return jsonify({'error': 'Invalid username or password'}), 401
    
@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')

    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT * FROM User WHERE email = ?", (email,))
    user = c.fetchone()
    conn.close()

    if user:
        return jsonify({'message': 'Email found'}), 200
    else:
        return jsonify({'error': 'Email not found'}), 404
    
@app.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    email = data.get('email')
    new_password = data.get('new_password')

    if not email or not new_password:
        return jsonify({'error': 'Email and new password are required'}), 400

    hashed_password = generate_password_hash(new_password)

    conn = get_db_connection()
    c = conn.cursor()
    c.execute("UPDATE User SET password = ? WHERE email = ?", (hashed_password, email))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Password has been successfully updated'}), 200

def generate_profile_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT profile_id FROM Profile ORDER BY profile_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()

    if last_id_row:
        last_id = last_id_row[0]  # e.g., "P005"
        numeric_part = int(last_id[1:]) + 1   # get "005", convert to 5, add 1
        return f'P{numeric_part:03d}'         # pad to "P006"
    else:
        return 'P001'  # First entry
    
@app.route('/profile', methods=['POST'])
def save_profile():
    # Get text fields from form
    user_id = request.form.get('userId')
    full_name = request.form.get('fullName')
    age = request.form.get('age')
    gender = request.form.get('gender')
    height = request.form.get('height')
    weight = request.form.get('weight')
    location = request.form.get('location')

    if not user_id or not full_name:
        return jsonify({'error': 'Missing required fields'}), 400

    # Handle profile_picture file
    profile_picture_file = request.files.get('profile_picture')
    profile_picture_base64 = None
    if profile_picture_file:
        # Read file bytes and encode as base64 string
        file_bytes = profile_picture_file.read()
        profile_picture_base64 = base64.b64encode(file_bytes).decode('utf-8')

    # Calculate BMI
    bmi = None
    if weight and height:
        try:
            bmi = round(float(weight) / ((float(height) / 100) ** 2), 2)
        except:
            bmi = None

    conn = get_db_connection()
    cur = conn.cursor()

    # Check if profile exists
    cur.execute("SELECT * FROM Profile WHERE user_id = ?", (user_id,))
    existing_profile = cur.fetchone()

    if existing_profile:
        # Update
        cur.execute("""
            UPDATE Profile SET full_name=?, age=?, gender=?, height=?, weight=?, bmi=?, location=?, profile_picture=?
            WHERE user_id=?
        """, (full_name, age, gender, height, weight, bmi, location, profile_picture_base64, user_id))
    else:
        # Insert new profile_id
        profile_id = generate_profile_id()
        cur.execute("""
            INSERT INTO Profile (profile_id, user_id, full_name, age, gender, height, weight, bmi, location, profile_picture)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (profile_id, user_id, full_name, age, gender, height, weight, bmi, location, profile_picture_base64))

    conn.commit()
    conn.close()

    return jsonify({'message': 'Profile saved successfully'}), 200

@app.route('/suggest-meals', methods=['POST'])
def suggest_meals():
    data = request.get_json()
    available_names = [name.strip().lower() for name in data.get('ingredients', [])]
    conn = get_db_connection()
    c = conn.cursor()

    # Get ingredient IDs for the provided names
    if not available_names:
        return jsonify({'meals': []})

    q_marks = ','.join('?' for _ in available_names)
    c.execute(f"SELECT ingredient_id, ingredient_name FROM Ingredient WHERE lower(ingredient_name) IN ({q_marks})", available_names)
    id_map = {row[1].strip().lower(): row[0] for row in c.fetchall()}
    available_ids = set(id_map.values())

    # Fetch all ingredient id-name pairs for lookup
    c.execute("SELECT ingredient_id, ingredient_name FROM Ingredient")
    id_to_name = {str(row[0]): row[1] for row in c.fetchall()}

    # Fetch all recipes
    c.execute("SELECT recipe_id, title, description, ingredients, instructions, nutrition_info, created_at FROM RecipeLibrary")
    recipes = c.fetchall()

    suggested_meals = []
    for recipe in recipes:
        recipe_ids = set(recipe[3].split(','))
        match_count = len(available_ids & recipe_ids)
        if match_count > 0:
            match_percentage = (match_count / len(recipe_ids)) * 100
            # Convert ingredient IDs to names for display
            ingredient_names = [id_to_name.get(rid.strip(), rid.strip()) for rid in recipe[3].split(',')]
            suggested_meals.append({
                'recipe_id': recipe[0],
                'title': recipe[1],
                'description': recipe[2],
                'ingredients': ', '.join(ingredient_names),
                'instructions': recipe[4],
                'nutrition_info': recipe[5],
                'created_at': recipe[6],
                'match_percentage': round(match_percentage, 1)
            })

    suggested_meals.sort(key=lambda x: x['match_percentage'], reverse=True)
    conn.close()
    return jsonify({'meals': suggested_meals})

@app.route('/meal-scan', methods=['POST'])
def meal_scan():
    try:
        user_id = request.form.get('user_id')
        if not user_id:
            return jsonify({'error': 'User ID is required'}), 400

        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided'}), 400

        image_file = request.files['image']
        if image_file.filename == '':
            return jsonify({'error': 'No selected file'}), 400

        # Save the image temporarily
        temp_path = f"./backend/temp/{uuid.uuid4()}.jpg"
        os.makedirs(os.path.dirname(temp_path), exist_ok=True)
        image_file.save(temp_path)

        # Process the image using the scanner service
        result = scanner.process_image(temp_path, user_id)

        # Clean up temporary file
        os.remove(temp_path)

        if result.get('success'):
            return jsonify(result), 201
        else:
            return jsonify(result), 400

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/scan-meal', methods=['POST'])
def scan_meal():
    """Endpoint to scan a meal from uploaded image"""
    file_path = None
    try:
        # Check if user_id is provided
        if 'user_id' not in request.form:
            return jsonify({'error': 'user_id is required', 'success': False}), 400
        
        user_id = request.form['user_id']
        
        # Check if image file is present
        if 'image' not in request.files:
            return jsonify({'error': 'No image file provided', 'success': False}), 400
        
        file = request.files['image']
        
        if file.filename == '':
            return jsonify({'error': 'No file selected', 'success': False}), 400
        
        if not allowed_file(file.filename):
            return jsonify({'error': 'Invalid file type. Allowed: png, jpg, jpeg, gif', 'success': False}), 400
        
        # Generate unique filename and meal scan ID
        filename = secure_filename(file.filename)
        unique_filename = f"{uuid.uuid4()}_{filename}"
        file_path = os.path.join(UPLOAD_FOLDER, unique_filename)
        meal_scan_id = str(uuid.uuid4())
        
        # Save file
        file.save(file_path)
        
        # Validate image
        if not validate_image(file_path):
            if file_path:
                os.remove(file_path)  # Clean up invalid file
            return jsonify({'error': 'Invalid image file', 'success': False}), 400
        
        # Use Clarifai for food recognition
        recognition_result = food_recognizer.analyze_image(file_path)
        
        if not recognition_result.get('success'):
            if file_path:
                os.remove(file_path)  # Clean up file if recognition fails
            return jsonify({
                'error': recognition_result.get('error', 'Recognition failed'),
                'success': False
            }), 400
        
        # Get food information
        food_name = recognition_result['food_name']
        confidence = recognition_result['confidence']
        alternatives = recognition_result['alternatives']
        nutrients = food_recognizer.get_nutrition_info(food_name)
        calories = nutrients.get('calories', 0)
        
        # Save to database
        conn = get_db_connection()
        c = conn.cursor()
        c.execute('''
            INSERT INTO MealScans (meal_scan_id, user_id, food_name, calories, nutrients, image_path)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (meal_scan_id, user_id, food_name, calories, json.dumps(nutrients), file_path))
        conn.commit()
        conn.close()
        
        return jsonify({
            'meal_scan_id': meal_scan_id,
            'food_name': food_name,
            'confidence': confidence,
            'calories': calories,
            'nutrients': nutrients,
            'image_path': file_path,
            'alternatives': alternatives,
            'success': True
        }), 201
        
    except Exception as e:
        if file_path and os.path.exists(file_path):
            os.remove(file_path)  # Clean up file on error
        return jsonify({'error': f'Error processing request: {str(e)}', 'success': False}), 500

@app.route('/api/meal-scans/<user_id>', methods=['GET'])
def get_meal_scans(user_id):
    """Get meal scan history for a user"""
    try:
        limit = int(request.args.get('limit', 50))
        
        if limit > 200:  # Prevent excessive data retrieval
            limit = 200
        
        conn = get_db_connection()
        c = conn.cursor()
        c.execute('''
            SELECT meal_scan_id, user_id, food_name, calories, nutrients, image_path, timestamp
            FROM MealScans
            WHERE user_id = ?
            ORDER BY timestamp DESC
            LIMIT ?
        ''', (user_id, limit))
        
        scans = []
        for row in c.fetchall():
            scans.append({
                'meal_scan_id': row[0],
                'user_id': row[1],
                'food_name': row[2],
                'calories': row[3],
                'nutrients': json.loads(row[4]) if row[4] else {},
                'image_path': row[5],
                'timestamp': row[6]
            })
        
        conn.close()
        return jsonify({'meal_scans': scans, 'success': True})
        
    except Exception as e:
        return jsonify({'error': f'Error retrieving history: {str(e)}', 'success': False}), 500

@app.route('/api/meal-scan/<meal_scan_id>', methods=['PUT'])
def update_meal_scan(meal_scan_id):
    """Update a meal scan entry"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided', 'success': False}), 400
        
        food_name = data.get('food_name')
        calories = data.get('calories')
        
        if not food_name and calories is None:
            return jsonify({'error': 'Either food_name or calories must be provided', 'success': False}), 400
        
        conn = get_db_connection()
        c = conn.cursor()
        
        if food_name and calories is not None:
            c.execute('UPDATE MealScans SET food_name = ?, calories = ? WHERE meal_scan_id = ?',
                     (food_name, calories, meal_scan_id))
        elif food_name:
            c.execute('UPDATE MealScans SET food_name = ? WHERE meal_scan_id = ?',
                     (food_name, meal_scan_id))
        else:
            c.execute('UPDATE MealScans SET calories = ? WHERE meal_scan_id = ?',
                     (calories, meal_scan_id))
        
        if c.rowcount > 0:
            conn.commit()
            conn.close()
            return jsonify({'success': True, 'message': 'Meal scan updated successfully'})
        else:
            conn.close()
            return jsonify({'error': 'Meal scan not found', 'success': False}), 404
            
    except Exception as e:
        return jsonify({'error': f'Error updating meal scan: {str(e)}', 'success': False}), 500

@app.route('/api/meal-scan/<meal_scan_id>', methods=['DELETE'])
def delete_meal_scan(meal_scan_id):
    """Delete a meal scan entry"""
    try:
        conn = get_db_connection()
        c = conn.cursor()
        
        # Get image path before deletion to clean up file
        c.execute('SELECT image_path FROM MealScans WHERE meal_scan_id = ?', (meal_scan_id,))
        result = c.fetchone()
        
        if result:
            image_path = result[0]
            
            # Delete from database
            c.execute('DELETE FROM MealScans WHERE meal_scan_id = ?', (meal_scan_id,))
            conn.commit()
            
            # Clean up image file
            if image_path and os.path.exists(image_path):
                os.remove(image_path)
            
            conn.close()
            return jsonify({'success': True, 'message': 'Meal scan deleted successfully'})
        else:
            conn.close()
            return jsonify({'error': 'Meal scan not found', 'success': False}), 404
            
    except Exception as e:
        return jsonify({'error': f'Error deleting meal scan: {str(e)}', 'success': False}), 500

@app.route('/api/nutrition-info/<food_name>', methods=['GET'])
def get_nutrition_info(food_name):
    """Get nutrition information for a specific food item"""
    try:
        quantity = request.args.get('quantity', '1 serving')
        
        # Mock nutrition data for demo
        nutrition_info = {
            'calories': 250,
            'protein': 12,
            'carbs': 30,
            'fat': 8,
            'fiber': 4,
            'sugar': 6,
            'sodium': 400
        }
        
        return jsonify({
            'food_name': food_name,
            'quantity': quantity,
            'nutrition': nutrition_info,
            'success': True
        })
        
    except Exception as e:
        return jsonify({'error': f'Error getting nutrition info: {str(e)}', 'success': False}), 500

@app.route('/api/search-food', methods=['GET'])
def search_food():
    """Search for food items and get nutrition info"""
    try:
        query = request.args.get('q', '').strip()
        
        if not query:
            return jsonify({'error': 'Search query is required', 'success': False}), 400
        
        # Mock search results for demo
        nutrition_info = {
            'calories': 250,
            'protein': 12,
            'carbs': 30,
            'fat': 8,
            'fiber': 4,
            'sugar': 6,
            'sodium': 400
        }
        
        return jsonify({
            'query': query,
            'results': [
                {
                    'food_name': query,
                    'calories': nutrition_info['calories'],
                    'nutrients': nutrition_info
                }
            ],
            'success': True
        })
        
    except Exception as e:
        return jsonify({'error': f'Error searching food: {str(e)}', 'success': False}), 500

@app.route('/api/images/<filename>')
def get_image(filename):
    """Serve uploaded images"""
    try:
        return send_from_directory(UPLOAD_FOLDER, filename)
    except Exception as e:
        return jsonify({'error': 'Image not found'}), 404

@app.route('/api/cleanup', methods=['POST'])
def cleanup_old_files():
    """Clean up old uploaded files (admin endpoint)"""
    try:
        # Define how old files should be before cleanup (e.g., 30 days)
        cutoff_date = datetime.now() - timedelta(days=30)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get old files
        cursor.execute('''
            SELECT image_path FROM MealScans 
            WHERE timestamp < ?
        ''', (cutoff_date.isoformat(),))
        
        old_files = cursor.fetchall()
        cleaned_count = 0
        
        # Delete old files
        for file_path, in old_files:
            if file_path and os.path.exists(file_path):
                os.remove(file_path)
                cleaned_count += 1
        
        cursor.execute('DELETE FROM MealScans WHERE timestamp < ?', (cutoff_date.isoformat(),))
        conn.commit()
        conn.close()
        
        return jsonify({
            'success': True,
            'message': f'Cleaned up {cleaned_count} old files',
            'cutoff_date': cutoff_date.isoformat()
        })
        
    except Exception as e:
        return jsonify({'error': f'Error during cleanup: {str(e)}', 'success': False}), 500

@app.route('/api/chatbot', methods=['POST'])
def chatbot():
    try:
        data = request.get_json()
        user_message = data.get('message', '')
        
        # Define the system role/prompt for workout and diet focus
        system_prompt = """You are a knowledgeable fitness and nutrition assistant. Your role is to help users with:

1. Workout routines and exercise recommendations
2. Diet plans and nutritional advice
3. Healthy lifestyle tips
4. Weight management strategies
5. Muscle building and strength training guidance
6. Meal planning and recipe suggestions
7. Supplement advice (general information only)

Guidelines:
- Always prioritize safety and recommend consulting healthcare professionals for medical concerns
- Provide evidence-based advice when possible
- Ask clarifying questions about user's goals, current fitness level, and any limitations
- Be encouraging and supportive
- If asked about topics outside fitness/nutrition, politely redirect the conversation back to health and wellness

Now, please respond to the user's question about fitness, nutrition, or wellness."""

        # Combine system prompt with user message
        full_prompt = f"{system_prompt}\n\nUser Question: {user_message}"
        
        model = genai.GenerativeModel('gemini-2.5-flash')
        response = model.generate_content(full_prompt)
        reply = response.text
        
        return jsonify({'reply': reply, 'success': True})
    except Exception as e:
        print(f"Error in /api/chatbot: {e}")
        return jsonify({'reply': 'Sorry, something went wrong. Please try asking about your fitness or nutrition goals!', 'success': False}), 500
if __name__ == '__main__':
    # Create necessary directories
    os.makedirs('./backend/temp', exist_ok=True)
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    
    # Initialize database
    init_db()
    
    # Set max file size
    app.config['MAX_CONTENT_LENGTH'] = MAX_FILE_SIZE
    
    print("\nStarting NextGenFitness API...")
    print(f"Upload folder: {UPLOAD_FOLDER}")
    print(f"Max file size: {MAX_FILE_SIZE / (1024*1024)}MB")
    print("\nAvailable meal scanner endpoints:")
    print("  POST /api/scan-meal - Scan meal from image")
    print("  GET  /api/meal-scans/<user_id> - Get user meal history")
    print("  PUT  /api/meal-scan/<meal_scan_id> - Update meal scan")
    print("  GET  /api/nutrition-info/<food_name> - Get nutrition info")
    print("  GET  /api/search-food - Search food items")
    print("  GET  /api/images/<filename> - Serve images")
    
    app.run(debug=True)
