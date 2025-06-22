from flask import Flask, request, jsonify,send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from werkzeug.utils import secure_filename
import sqlite3
import base64
import re # Import the re module for regeximport os
import random
import os
import shutil
import json
import uuid
from datetime import datetime, timedelta
from PIL import Image
from food_recognition import FoodRecognition
import google.generativeai as genai
from dateutil.relativedelta import relativedelta

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
EXERCISE_FOLDER = os.path.join(BASE_DIR, 'exercises')
IMAGE_DIR = EXERCISE_FOLDER

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
    conn = sqlite3.connect('NextGenFitness.db')
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    c = conn.cursor()

    # Create User table
    c.execute('''CREATE TABLE IF NOT EXISTS User
                (user_id TEXT PRIMARY KEY,
                username TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                role INTEGER)''')

    # Create Profile table
    c.execute('''CREATE TABLE IF NOT EXISTS Profile
                (profile_id TEXT PRIMARY KEY,
                user_id TEXT UNIQUE NOT NULL,
                full_name TEXT,
                age INTEGER,
                gender TEXT,
                height REAL,
                weight REAL,
                bmi REAL,
                location TEXT,
                profile_picture TEXT,
                FOREIGN KEY (user_id) REFERENCES User(user_id))''')

    # Create Goal table
    c.execute('''CREATE TABLE IF NOT EXISTS Goal
                (goal_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                workout_plan TEXT,
                diet_plan TEXT,
                goal_type TEXT,
                target_value REAL,
                current_value REAL,
                status TEXT,
                FOREIGN KEY (user_id) REFERENCES User(user_id))''')

    # Create UserDietPreference table
    c.execute('''CREATE TABLE IF NOT EXISTS UserDietPreference
                (diet_pref_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                ingredient_id TEXT,
                diet_type TEXT,
                dietary_goal TEXT,
                allergies TEXT,
                calories INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES User(user_id))''')


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
    
    # Create Feedback table
    c.execute('''CREATE TABLE IF NOT EXISTS Feedback (
                feedback_id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                submitted_at DATE,
                category TEXT,
                feedback_text TEXT,
                status TEXT,
                FOREIGN KEY (user_id) REFERENCES User(user_id)
            )''')
                
    conn.commit()
    conn.close()

def generate_user_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT user_id FROM User ORDER BY user_id DESC LIMIT 1")
    last = c.fetchone()
    conn.close()
    if last and last['user_id']:
        last_num = int(last['user_id'][1:])
        new_num = last_num + 1
    else:
        new_num = 1
    return f"U{new_num:03d}"

def generate_profile_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT profile_id FROM Profile ORDER BY profile_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()
    if last_id_row:
        last_id = last_id_row['profile_id']
        numeric_part = int(last_id[1:]) + 1
        return f'P{numeric_part:03d}'
    else:
        return 'P001'

def generate_goal_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT goal_id FROM Goal ORDER BY goal_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()
    if last_id_row:
        last_id = last_id_row['goal_id']
        numeric_part = int(last_id[1:]) + 1
        return f'G{numeric_part:03d}'
    else:
        return 'G001'

def generate_diet_pref_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT diet_pref_id FROM UserDietPreference ORDER BY diet_pref_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()
    if last_id_row:
        last_id = last_id_row['diet_pref_id']
        numeric_part = int(last_id[3:]) + 1
        return f'UDP{numeric_part:03d}'
    else:
        return 'UDP001'

def generate_feedback_id():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT feedback_id FROM Feedback ORDER BY feedback_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()
    if last_id_row:
        last_id = last_id_row['feedback_id']
        numeric_part = int(last_id[1:]) + 1
        return f'F{numeric_part:03d}'
    else:
        return 'F001'

def generate_log_id(): #
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT log_id FROM SystemLog ORDER BY log_id DESC LIMIT 1")
    last_id_row = c.fetchone()
    conn.close()
    if last_id_row:
        last_id = last_id_row['log_id']
        numeric_part = int(last_id[1:]) + 1
        return f'L{numeric_part:03d}'
    else:
        return 'L001'

@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    username = data.get('username')
    email = data.get('email')
    password_raw = data.get('password') # Get raw password for hashing
    password = generate_password_hash(password_raw) # Hash the password
    role = int(data.get('role', 1))

    gender = data.get('gender')
    weight = data.get('weight')
    height = data.get('height')
    age = data.get('age')
    main_goal = data.get('goal')
    target_weight = data.get('target_weight')
    allergy = data.get('allergy')

    if not all([username, email, password_raw, gender, weight, height, age, main_goal, target_weight]):
        return jsonify({'error': 'Missing required fields for signup (username, email, password, gender, weight, height, age, goal, target_weight)'}), 400
    
    # Username length validation
    if len(username) < 3:
        return jsonify({'error': 'Username must be at least 3 characters long.'}), 400

    # Username character validation: Allow only alphanumeric characters and underscores
    if not re.match(r'^[a-zA-Z0-9_]+$', username):
        return jsonify({'error': 'Username can only contain alphanumeric characters and underscores.'}), 400

    # Username leading/trailing underscore validation
    if username.startswith('_') or username.endswith('_'):
        return jsonify({'error': 'Username cannot start or end with an underscore.'}), 400

    # Username consecutive underscore validation
    if '_' in username:
        return jsonify({'error': 'Username cannot contain consecutive underscores.'}), 400
    
    # Email format validation
    # This regex covers most common email formats.
    email_regex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(email_regex, email):
        return jsonify({'error': 'Invalid email format. Please use a valid email address.'}), 400

    conn = get_db_connection()
    c = conn.cursor()

    try:
        # Check if username exists
        c.execute("SELECT * FROM User WHERE username = ?", (username,))
        if c.fetchone():
            return jsonify({'error': 'Username already exists. Please choose a different username.'}), 409

        # Check if email exists
        c.execute("SELECT * FROM User WHERE email = ?", (email,))
        if c.fetchone():
            return jsonify({'error': 'Email already registered. Please use a different email address.'}), 409

        new_user_id = generate_user_id()

        # Insert user
        c.execute("INSERT INTO User (user_id, username, email, password, role) VALUES (?, ?, ?, ?, ?)",
                  (new_user_id, username, email, password, role))

        # Calculate BMI
        bmi = None
        if weight and height:
            try:
                bmi = round(float(weight) / ((float(height) / 100) ** 2), 2)
            except (ValueError, TypeError):
                bmi = None

        # Insert into Profile table
        profile_id = generate_profile_id()
        c.execute("""
            INSERT INTO Profile (profile_id, user_id, full_name, age, gender, height, weight, bmi)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (profile_id, new_user_id, username, int(age), gender, float(height), float(weight), bmi))

        # Insert into Goal table
        goal_id = generate_goal_id()
        c.execute("""
            INSERT INTO Goal (goal_id, user_id, goal_type, target_value, current_value, status)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (goal_id, new_user_id, main_goal, float(target_weight), float(weight), 'In Progress'))

        # Insert into UserDietPreference table
        diet_pref_id = generate_diet_pref_id()
        allergy_text = allergy if allergy else None
        c.execute("""
            INSERT INTO UserDietPreference (diet_pref_id, user_id, dietary_goal, allergies)
            VALUES (?, ?, ?, ?)
        """, (diet_pref_id, new_user_id, main_goal, allergy_text))

        conn.commit()
        return jsonify({'message': 'User registered successfully', 'user_id': new_user_id}), 200

    except sqlite3.IntegrityError as e:
        conn.rollback()
        return jsonify({'error': f'Database error: {str(e)}'}), 500
    except Exception as e:
        conn.rollback()
        return jsonify({'error': f'An unexpected error occurred: {str(e)}'}), 500
    finally:
        conn.close()

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    conn = get_db_connection()
    c = conn.cursor()
    
    # Fetch user info
    c.execute("SELECT user_id, password, role FROM User WHERE username = ?", (username,))
    user = c.fetchone()
    
    if user and check_password_hash(user['password'], password):
        # Handle banned and maintenance users
        if user['role'] == 2:
            conn.close()
            return jsonify({'error': 'Your account has been disabled. Please contact support.'}), 403
        if user['role'] == 3 and user['role'] != 0:
            conn.close()
            return jsonify({'error': 'System is currently under maintenance. Please try again later.'}), 403

        user_id = user['user_id']
        
        # Log login attempt
        try:
            log_id = generate_log_id()
            action = "Logged In"
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            c.execute(
                "INSERT INTO SystemLog (log_id, user_id, action, timestamp) VALUES (?, ?, ?, ?)",
                (log_id, user_id, action, timestamp)
            )
        except Exception as e:
            print(f"Error logging login activity: {e}")
            # Still allow login to proceed

        # 🔁 Auto-update progress for all workout plans of this user
        try:
            c.execute("SELECT * FROM WorkoutPlan WHERE user_id = ?", (user_id,))
            plans = c.fetchall()

            for plan in plans:
                plan_id = plan['plan_id']

                # Total exercises assigned to this plan
                c.execute("""
                    SELECT COUNT(*) AS total_exercises
                    FROM WorkoutPlanExercise
                    WHERE plan_id = ?
                """, (plan_id,))
                total_exercises = c.fetchone()['total_exercises']

                if total_exercises == 0:
                    progress = 0
                else:
                    # Checked daily reminders for this plan
                    c.execute("""
                        SELECT COUNT(*) AS checked_reminders
                        FROM notifications
                        WHERE user_id = ? AND plan_id = ? AND type = 'daily reminder' AND checked = 1
                    """, (user_id, plan_id))
                    checked_reminders = c.fetchone()['checked_reminders']

                    progress = min(int((checked_reminders / total_exercises) * 100), 100)

                # Update progress
                c.execute("UPDATE WorkoutPlan SET progress = ? WHERE plan_id = ?", (progress, plan_id))

        except Exception as e:
            print(f"❌ Error updating workout progress: {e}")

        conn.commit()
        conn.close()
        return jsonify({
            'message': 'Login successful',
            'user_id': user_id,
            'role': user['role']
        }), 200

    else:
        conn.close()
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
    """
    This endpoint is for generic password resets (e.g., from a 'forgot password' flow)
    where the current password is NOT required.
    """
    data = request.get_json()
    email = data.get('email')
    new_password = data.get('new_password')

    if not email or not new_password:
        return jsonify({'error': 'Email and new password are required'}), 400

    hashed_password = generate_password_hash(new_password)

    conn = get_db_connection()
    c = conn.cursor()
    try:
        c.execute("UPDATE User SET password = ? WHERE email = ?", (hashed_password, email))
        if c.rowcount == 0:
            conn.rollback()
            return jsonify({'error': 'User with provided email not found'}), 404
        conn.commit()
        return jsonify({'message': 'Password has been successfully updated'}), 200
    except Exception as e:
        conn.rollback()
        print(f"Error updating password: {e}")
        return jsonify({'error': 'Internal server error during password update'}), 500
    finally:
        conn.close()

# NEW ENDPOINT: Reset password from profile page (requires current password verification)
@app.route('/api/profile/reset-password', methods=['POST'])
def profile_reset_password():
    """
    API endpoint for users to reset their password from the profile page.
    Requires user_id, current_password, and new_password.
    Verifies the current password before updating.
    """
    data = request.get_json()
    user_id = data.get('user_id')
    current_password = data.get('current_password')
    new_password = data.get('new_password')

    # Input validation
    if not all([user_id, current_password, new_password]):
        return jsonify({'error': 'Missing required fields: user_id, current_password, and new_password'}), 400
    
    if len(new_password) < 6:
        return jsonify({'error': 'New password must be at least 6 characters long.'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Retrieve user's current hashed password from the database
        cursor.execute("SELECT password FROM User WHERE user_id = ?", (user_id,))
        user_row = cursor.fetchone()

        if not user_row:
            return jsonify({'error': 'User not found'}), 404

        stored_hashed_password = user_row['password']

        # Verify the provided current password against the stored hashed password
        if not check_password_hash(stored_hashed_password, current_password):
            return jsonify({'error': 'Invalid current password'}), 401

        # Hash the new password
        hashed_new_password = generate_password_hash(new_password)

        # Update the password in the database
        cursor.execute("UPDATE User SET password = ? WHERE user_id = ?", (hashed_new_password, user_id))
        conn.commit()

        return jsonify({'message': 'Password reset successfully!'}), 200

    except sqlite3.Error as e:
        print(f"Database error in profile_reset_password: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in profile_reset_password: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/profile', methods=['POST'])
def save_profile():
    user_id = request.form.get('userId')
    full_name = request.form.get('fullName')
    age = request.form.get('age')
    gender = request.form.get('gender')
    height = request.form.get('height')
    weight = request.form.get('weight')
    location = request.form.get('location')

    if not user_id or not full_name:
        return jsonify({'error': 'Missing required fields'}), 400

    profile_picture_file = request.files.get('profile_picture')
    profile_picture_base64 = None
    if profile_picture_file:
        file_bytes = profile_picture_file.read()
        profile_picture_base64 = base64.b64encode(file_bytes).decode('utf-8')

    bmi = None
    if weight and height:
        try:
            bmi = round(float(weight) / ((float(height) / 100) ** 2), 2)
        except (ValueError, TypeError):
            bmi = None

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute("SELECT * FROM Profile WHERE user_id = ?", (user_id,))
    existing_profile = cur.fetchone()

    if existing_profile:
        cur.execute("""
            UPDATE Profile SET full_name=?, age=?, gender=?, height=?, weight=?, bmi=?, location=?, profile_picture=?
            WHERE user_id=?
        """, (full_name, age, gender, height, weight, bmi, location, profile_picture_base64, user_id))
    else:
        profile_id = generate_profile_id()
        cur.execute("""
            INSERT INTO Profile (profile_id, user_id, full_name, age, gender, height, weight, bmi, location, profile_picture)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (profile_id, user_id, full_name, age, gender, height, weight, bmi, location, profile_picture_base64))

    conn.commit()
    conn.close()

    return jsonify({'message': 'Profile saved successfully'}), 200

@app.route('/exercise-images/<folder>/<filename>')
def serve_exercise_image(folder, filename):
    return send_from_directory(os.path.join(IMAGE_DIR, folder), filename)

@app.route('/search')
def search_exercises():
    query = request.args.get('q', '').lower()
    conn = get_db_connection()
    cur = conn.cursor()
    
    cur.execute("SELECT * FROM Exercise WHERE LOWER(name) LIKE ?", ('%' + query + '%',))
    rows = cur.fetchall()
    conn.close()

    exercises = []
    for row in rows[:10]:  # limit to first 10 results
        ex = dict(row)
        
        # Handle image URLs (assuming folder naming is like '3_4_Sit-up')
        folder_name = ex['name'].replace('/', '_').replace(' ', '_')
        image_dir = os.path.join(EXERCISE_FOLDER, folder_name)
        image_urls = []
        if os.path.exists(image_dir):
            for filename in sorted(os.listdir(image_dir)):
                if filename.endswith('.jpg'):
                    image_urls.append(f'/exercise-images/{folder_name}/{filename}')
        ex['image_urls'] = image_urls

        # Convert instruction from string to list if necessary
        if isinstance(ex['instructions'], str):
            ex['instructions'] = [step.strip() for step in ex['instructions'].split('.') if step.strip()]

        exercises.append(ex)

    return jsonify({'exercises': exercises})

@app.route('/exercises')
def get_exercises():

    page = int(request.args.get('page', 1))
    per_page = int(request.args.get('per_page', 10))
    offset = (page - 1) * per_page

    # Get filter parameters
    level = request.args.get('level')
    mechanic = request.args.get('mechanic')
    equipment = request.args.get('equipment')
    primary_muscle = request.args.get('primaryMuscle')
    category = request.args.get('category')

    query = "SELECT * FROM Exercise WHERE 1=1"
    params = []

    # Add filters dynamically
    if level:
        query += " AND level = ?"
        params.append(level)
    if mechanic:
        query += " AND mechanic = ?"
        params.append(mechanic)
    if equipment:
        query += " AND equipment = ?"
        params.append(equipment)
    if primary_muscle:
        query += " AND primaryMuscles LIKE ?"
        params.append(f"%{primary_muscle}%")
    if category:
        query += " AND category = ?"
        params.append(category)

    # Add pagination
    query += " LIMIT ? OFFSET ?"
    params.extend([per_page, offset])

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    rows = cur.fetchall()
    conn.close()

    exercises = []
    for row in rows:
        ex = dict(row)

        # Generate image URLs
        folder_name = ex['name'].replace('/', '_').replace(' ', '_')
        image_dir = os.path.join(EXERCISE_FOLDER, folder_name)
        image_urls = []
        if os.path.exists(image_dir):
            for filename in sorted(os.listdir(image_dir)):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                    image_urls.append(f'/exercise-images/{folder_name}/{filename}')
        ex['image_urls'] = image_urls

        # Convert instructions string to list
        if isinstance(ex['instructions'], str):
            ex['instructions'] = [step.strip() for step in ex['instructions'].split('.') if step.strip()]

        exercises.append(ex)

    return jsonify({'exercises': exercises})

#customize-exercise-libray
@app.route('/exercise-library', methods=['GET'])
def get_exercise_library():
    page = int(request.args.get('page', 1))
    per_page = int(request.args.get('per_page', 10))
    offset = (page - 1) * per_page

    # Filters
    level = request.args.get('level')
    mechanic = request.args.get('mechanic')
    equipment = request.args.get('equipment')
    primary_muscle = request.args.get('primaryMuscle')
    category = request.args.get('category')

    query = "SELECT * FROM Exercise WHERE 1=1"
    params = []

    if level:
        query += " AND level = ?"
        params.append(level)
    if mechanic:
        query += " AND mechanic = ?"
        params.append(mechanic)
    if equipment:
        query += " AND equipment = ?"
        params.append(equipment)
    if primary_muscle:
        query += " AND primaryMuscles LIKE ?"
        params.append(f"%{primary_muscle}%")
    if category:
        query += " AND category = ?"
        params.append(category)

    query += " LIMIT ? OFFSET ?"
    params.extend([per_page, offset])

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    rows = cur.fetchall()
    conn.close()

    exercises = []
    for row in rows:
        ex = dict(row)
        folder_name = ex['name'].replace('/', '_').replace(' ', '_')
        image_dir = os.path.join(EXERCISE_FOLDER, folder_name)
        image_urls = []

        if os.path.exists(image_dir):
            for filename in sorted(os.listdir(image_dir)):
                if filename.lower().endswith(('.jpg', '.jpeg', '.png')):
                    image_urls.append(f'/exercise-images/{folder_name}/{filename}')
        ex['image_urls'] = image_urls

        # Convert instructions to list
        if isinstance(ex['instructions'], str):
            ex['instructions'] = [s.strip() for s in ex['instructions'].split('.') if s.strip()]

        exercises.append(ex)

    return jsonify({'exercises': exercises})

@app.route('/generate-plan', methods=['POST'])
def generate_workout_plan():
    data = request.get_json()

    user_id = str(data.get('user_id'))
    level = data.get('level')
    mechanic = data.get('mechanic')
    equipment = data.get('equipment')
    primaryMuscle = data.get('primaryMuscle')
    category = data.get('category')
    duration_months = data.get('duration', 3)
    start_date_str = data.get('start_date')  # optional: e.g. "2025-06-21"

    if user_id.isdigit():
        user_id = f"U{int(user_id):03d}"

    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400

    query = "SELECT * FROM Exercise WHERE 1=1"
    params = []

    if level:
        query += " AND level = ?"
        params.append(level)
    if mechanic:
        query += " AND mechanic = ?"
        params.append(mechanic)
    if equipment:
        query += " AND equipment = ?"
        params.append(equipment)
    if primaryMuscle:
        query += " AND primaryMuscles = ?"
        params.append(primaryMuscle)
    if category:
        query += " AND category = ?"
        params.append(category)

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(query, params)
    rows = cur.fetchall()

    if not rows:
        conn.close()
        return jsonify({'error': 'No exercises found for the selected preferences.'}), 404

    exercises = [dict(row) for row in rows]
    random.shuffle(exercises)

    total_workout_days = duration_months * 4 * 3  # 3 days/week × 4 weeks/month
    exercises_per_day = 3
    total_exercises_needed = total_workout_days * exercises_per_day

    plan = []
    while len(plan) < total_exercises_needed:
        plan.extend(exercises)
    plan = plan[:total_exercises_needed]


    # Set the start date
    if start_date_str:
        try:
            start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
        except ValueError:
            return jsonify({'error': 'Invalid start_date format. Use %Y-%m-%d'}), 400
    else:
        start_date = datetime.today()

    # Insert into WorkoutPlan
    cur.execute(
        "INSERT INTO WorkoutPlan (user_id, duration_months) VALUES (?, ?)",
        (user_id, duration_months)
    )
    plan_id = cur.lastrowid

    # Insert into WorkoutPlanExercise with actual dates
    plan_by_dates = {}
    for day_index in range(total_workout_days):
        workout_date = start_date + timedelta(days=day_index * 2)  # e.g., every 2 days
        formatted_date = workout_date.strftime("%Y-%m-%d")

        for j in range(exercises_per_day):
            exercise_index = day_index * exercises_per_day + j
            ex = plan[exercise_index]

            cur.execute('''
                INSERT INTO WorkoutPlanExercise (plan_id, Exercise_ID, date)
                VALUES (?, ?, ?)
            ''', (plan_id, ex['Exercise_ID'], formatted_date))

            plan_by_dates[formatted_date] = plan_by_dates.get(formatted_date, []) + [ex]

    conn.commit()
    conn.close()

    return jsonify({
        'message': 'Workout plan generated and saved with dates',
        'plan_id': plan_id,
        'plan': plan_by_dates
    })

@app.route('/get-plans/<user_id>', methods=['GET'])
def get_plans(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('SELECT * FROM WorkoutPlan WHERE user_id = ?', (user_id,))
    plans = cursor.fetchall()
    conn.close()

    return jsonify({'plans': [dict(plan) for plan in plans]})

#get user plan for progress
@app.route('/get-user-plans/<user_id>', methods=['GET'])
def get_user_plans(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('SELECT * FROM WorkoutPlan WHERE user_id = ?', (user_id,))
    plans = cursor.fetchall()
    conn.close()

    return jsonify([dict(plan) for plan in plans])

@app.route('/get-plan-dates/<int:plan_id>', methods=['GET'])
def get_plan_dates(plan_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT DISTINCT date
        FROM WorkoutPlanExercise
        WHERE plan_id = ?
        ORDER BY date
    ''', (plan_id,))
    
    dates = cursor.fetchall()
    conn.close()

    # Convert to readable format (optional: e.g. "2025-06-21 (Saturday)")
    date_list = [row['date'] for row in dates]
    return jsonify({'dates': date_list})

@app.route('/get-plan-date/<int:plan_id>/<string:date_str>', methods=['GET'])
def get_plan_date(plan_id, date_str):
    conn = get_db_connection()
    cursor = conn.cursor()

    # Validate date format
    try:
        datetime.strptime(date_str, "%Y-%m-%d")
    except ValueError:
        return jsonify({"error": "Invalid date format. Use %Y-%m-%d"}), 400

    cursor.execute('''
        SELECT w.Workout_id, w.exercise_id, w.date, e.*
        FROM WorkoutPlanExercise w
        JOIN Exercise e ON w.exercise_id = e.Exercise_ID
        WHERE w.plan_id = ? AND w.date = ?
    ''', (plan_id, date_str))

    exercises = cursor.fetchall()
    result = []
    for ex in exercises:
        exercise_dict = dict(ex)
        exercise_dict['instructions'] = [s.strip() for s in exercise_dict['instructions'].split('.') if s.strip()]

        folder = exercise_dict['name'].replace('/', '_').replace(' ', '_')
        image_dir = os.path.join(EXERCISE_FOLDER, folder)
        if os.path.exists(image_dir):
            exercise_dict['image_urls'] = [
                f"/exercise-images/{folder}/{img}" for img in sorted(os.listdir(image_dir))
                if img.lower().endswith(('.jpg', '.jpeg', '.png'))
            ]
        else:
            exercise_dict['image_urls'] = []

        result.append(exercise_dict)

    conn.close()
    return jsonify({'exercises': result})

@app.route('/add-exercise', methods=['POST'])
def add_exercise():
    data = request.get_json()

    name = data.get('name')
    level = data.get('level')
    mechanic = data.get('mechanic')
    equipment = data.get('equipment')
    category = data.get('category')
    instructions = data.get('instructions')
    
    # ✅ Decode the muscles list (already a list in JSON)
    primary_muscles_list = data.get('primaryMuscles', [])
    if isinstance(primary_muscles_list, list):
        primary_muscles_str = json.dumps(primary_muscles_list)  # Save as JSON string
    else:
        primary_muscles_str = json.dumps([primary_muscles_list])  # Fallback for single muscle

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO Exercise (name, level, mechanic, equipment, primaryMuscles, category, instructions)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (name, level, mechanic, equipment, primary_muscles_str, category, instructions))
    
    exercise_id = cursor.lastrowid
    conn.commit()
    conn.close()

    return jsonify({'message': 'Exercise added successfully', 'id': exercise_id})

#update exercise in plan
@app.route('/update-exercise-plan', methods=['POST'])
def update_exercise_plan():
    data = request.get_json()
    workout_id = data.get('workout_id')
    new_exercise_id = data.get('exercise_id') or data.get('new_exercise_id')
    new_date = data.get('date')  # Optional

    if not workout_id or not new_exercise_id:
        print("Incoming data:", data)
        return jsonify({'error': 'Missing workout_id or exercise_id'}), 400
        
    conn = get_db_connection()
    cur = conn.cursor()

    # Build the update query
    if new_date:
        cur.execute('''
            UPDATE WorkoutPlanExercise
            SET exercise_id = ?, date = ?
            WHERE Workout_id = ?
        ''', (new_exercise_id, new_date, workout_id))
    else:
        cur.execute('''
            UPDATE WorkoutPlanExercise
            SET exercise_id = ?
            WHERE Workout_id = ?
        ''', (new_exercise_id, workout_id))

    conn.commit()
    conn.close()

    return jsonify({'message': 'Workout updated successfully'})

#delete exercise in plan
@app.route('/delete-exercise-plan', methods=['POST'])
def delete_exercise_plan():
    data = request.get_json()
    workout_id = data.get('workout_id')

    if not workout_id:
        return jsonify({'error': 'Missing workout_id'}), 400

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute('DELETE FROM WorkoutPlanExercise WHERE Workout_id = ?', (workout_id,))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Workout entry deleted successfully'})

@app.route('/update-exercise/<int:exercise_id>', methods=['PUT'])
def update_exercise(exercise_id):
    data = request.json
    print('RECEIVED primaryMuscles:', data['primaryMuscles'], type(data['primaryMuscles']))
    conn = get_db_connection()
    cur = conn.cursor()

    # Convert list to JSON string
    primary_muscles_json = json.dumps(data['primaryMuscles'])

    cur.execute("""
        UPDATE Exercise
        SET name=?, level=?, mechanic=?, equipment=?, primaryMuscles=?, category=?, instructions=?
        WHERE Exercise_ID=?
    """, (
        data['name'],
        data['level'],
        data['mechanic'],
        data['equipment'],
        primary_muscles_json,  # use JSON string
        data['category'],
        data['instructions'],
        exercise_id
    ))

    conn.commit()
    conn.close()
    return jsonify({'message': 'Exercise updated'}), 200

def upload_exercise_images(exercise_id):
    import os
    from werkzeug.utils import secure_filename

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT name FROM Exercise WHERE Exercise_ID = ?", (exercise_id,))
    row = cur.fetchone()
    conn.close()

    if not row:
        return jsonify({'error': 'Exercise not found'}), 404

    exercise_name = row['name']
    folder_name = exercise_name.replace('/', '_').replace(' ', '_')
    save_dir = os.path.join(EXERCISE_FOLDER, folder_name)
    os.makedirs(save_dir, exist_ok=True)

    for i in range(2):
        file = request.files.get(f'image{i}')
        if file:
            ext = file.filename.rsplit('.', 1)[1].lower()
            if ext not in ['png', 'jpg', 'jpeg']:
                return jsonify({'error': f'Invalid file type for image{i}'}), 400
            file_path = os.path.join(save_dir, f"{i}.png")
            file.save(file_path)

    return jsonify({'message': 'Images uploaded successfully'}), 200

@app.route('/delete-exercise/<int:exercise_id>', methods=['DELETE'])
def delete_exercise(exercise_id):
    conn = get_db_connection()
    cur = conn.cursor()

    # Get exercise name for deleting image folder
    cur.execute("SELECT name FROM Exercise WHERE Exercise_ID = ?", (exercise_id,))
    row = cur.fetchone()

    if row is None:
        conn.close()
        return jsonify({'error': 'Exercise not found'}), 404

    exercise_name = row['name']
    folder_name = exercise_name.replace('/', '_').replace(' ', '_')
    folder_path = os.path.join(EXERCISE_FOLDER, folder_name)

    # Delete from DB
    cur.execute("DELETE FROM Exercise WHERE Exercise_ID = ?", (exercise_id,))
    conn.commit()
    conn.close()

    # Delete image folder if exists
    if os.path.exists(folder_path):
        shutil.rmtree(folder_path)

    return jsonify({'message': f'Exercise {exercise_name} deleted successfully'}), 200

#save custom plan
@app.route('/save-custom-plan', methods=['POST'])
def save_custom_plan():
    data = request.get_json()

    user_id = data.get('user_id')
    exercise_ids = data.get('exercise_ids', [])
    duration = data.get('duration', 3)  # default to 3 months

    if not user_id or not exercise_ids:
        return jsonify({"error": "Missing user_id or exercise_ids"}), 400

    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Insert new workout plan
        cursor.execute('''
            INSERT INTO WorkoutPlan (user_id, duration_months, created_at)
            VALUES (?, ?, ?)
        ''', (user_id, duration, datetime.now().strftime('%Y-%m-%d %H:%M:%S')))
        conn.commit()

        plan_id = cursor.lastrowid

        # Settings for custom distribution
        exercises_per_day = 3
        total_days = (len(exercise_ids) + exercises_per_day - 1) // exercises_per_day
        start_date = datetime.now().date()

        for day_index in range(total_days):
            target_date = start_date + timedelta(days=day_index)
            for i in range(exercises_per_day):
                exercise_index = day_index * exercises_per_day + i
                if exercise_index >= len(exercise_ids):
                    break
                exercise_id = exercise_ids[exercise_index]

                cursor.execute('''
                    INSERT INTO WorkoutPlanExercise (plan_id, Exercise_ID, date)
                    VALUES (?, ?, ?)
                ''', (plan_id, exercise_id, target_date.strftime('%Y-%m-%d')))

        conn.commit()
        conn.close()

        return jsonify({"success": True, "plan_id": plan_id})

    except Exception as e:
        print("❌ Error:", e)
        return jsonify({"error": str(e)}), 500
#delete plan
@app.route('/delete-plan/<int:plan_id>', methods=['DELETE'])
def delete_plan(plan_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('DELETE FROM WorkoutPlanExercise WHERE plan_id = ?', (plan_id,))
    cursor.execute('DELETE FROM WorkoutPlan WHERE plan_id = ?', (plan_id,))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Plan deleted'}), 200
   
#check percentage of progress
@app.route('/check_workout_progress/<int:plan_id>', methods=['POST'])
def check_workout_progress(plan_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    # 1. Get WorkoutPlan info (start date and duration)
    cursor.execute('''
        SELECT created_at, duration_months
        FROM WorkoutPlan
        WHERE plan_id = ?
    ''', (plan_id,))
    plan = cursor.fetchone()

    if not plan:
        conn.close()
        return jsonify({'error': '❌ WorkoutPlan not found'}), 404

    created_at = plan['created_at']
    duration_months = plan['duration_months']

    try:
        start_date = datetime.strptime(created_at, '%Y-%m-%d %H:%M:%S')
    except ValueError:
        # In case your DB stores it in a shorter format
        start_date = datetime.strptime(created_at, '%Y-%m-%d')

    end_date = start_date + relativedelta(months=duration_months)
    total_days = (end_date - start_date).days

    # 2. Count checked daily reminder notifications for that plan
    cursor.execute('''
        SELECT COUNT(*) AS completed_days
        FROM notifications
        WHERE plan_id = ? AND type = 'daily reminder' AND checked = 1
    ''', (plan_id,))
    completed_days = cursor.fetchone()['completed_days']

    # 3. Calculate progress
    progress = int((completed_days / total_days) * 100) if total_days > 0 else 0

    # 4. Update the WorkoutPlan progress
    cursor.execute('''
        UPDATE WorkoutPlan
        SET progress = ?
        WHERE plan_id = ?
    ''', (progress, plan_id))
    conn.commit()
    conn.close()

    return jsonify({
        'message': f'✅ Progress updated to {progress}%',
        'progress': progress,
        'completed_days': completed_days,
        'total_days': total_days
    }), 200

#mark exercise for progress analytics
@app.route('/mark-exercise-status/<user_id>', methods=['POST'])
def mark_exercise_status(user_id):
    data = request.get_json()
    today = datetime.now().strftime('%Y-%m-%d')
    status_to_mark = data.get('status')  # 'completed' or 'overdue'
    plan_id = data.get('plan_id')
    exercise_id = data.get('exercise_id')
    date_str = data.get('date')  # yyyy-mm-dd

    if status_to_mark not in ['completed', 'overdue']:
        return jsonify({'error': 'Invalid status'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Check if already exists
    cursor.execute('''
        SELECT * FROM ExerciseStatus
        WHERE user_id = ? AND Exercise_ID = ? AND plan_id = ? AND date = ?
    ''', (user_id, exercise_id, plan_id, date_str))
    existing = cursor.fetchone()

    if existing:
        # Already marked
        return jsonify({'message': 'Already recorded for this date'}), 200

    # Insert status
    cursor.execute('''
        INSERT INTO ExerciseStatus (user_id, Exercise_ID, plan_id, date, status)
        VALUES (?, ?, ?, ?, ?)
    ''', (user_id, exercise_id, plan_id, date_str, status_to_mark))
    conn.commit()
    conn.close()

    return jsonify({'message': f'Exercise marked as {status_to_mark}'}), 200

# --- NEW ENDPOINT TO GET ALL USERS WITH PROFILE DATA ---
@app.route('/api/users', methods=['GET'])
def get_all_users():
    """
    API endpoint to get all registered users with their profile information.
    Joins User and Profile tables.
    Returns:
        JSON response with a list of user data or an error message.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Join User and Profile tables to get comprehensive user data
        cursor.execute("""
            SELECT
                U.user_id,
                U.username,
                U.email,
                U.role,
                P.full_name,
                P.age,
                P.gender,
                P.height,
                P.weight,
                P.bmi,
                P.location,
                P.profile_picture
            FROM
                User AS U
            LEFT JOIN
                Profile AS P ON U.user_id = P.user_id
        """)
        users_data = cursor.fetchall()

        users_list = []
        for user_row in users_data:
            user_dict = dict(user_row)
            # Convert role from integer to string ('Admin' or 'User')
            user_dict['role'] = 'Admin' if user_dict['role'] == 0 else 'User'
            users_list.append(user_dict)

        return jsonify(users_list), 200
    except sqlite3.Error as e:
        print(f"Database error in get_all_users: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_all_users: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

# --- NEW ENDPOINT TO GET TOTAL USERS COUNT ---
@app.route('/api/users/count', methods=['GET'])
def get_total_users_count():
    """
    API endpoint to get the total number of users from the 'User' table.
    Expects a GET request.
    Returns:
        JSON response with 'total_users' count or an error message.
    """
    conn = None # Initialize conn to None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Execute the query to count rows in the 'User' table
        cursor.execute("SELECT COUNT(*) FROM User")
        total_users = cursor.fetchone()[0] # Fetch the count (first column of the first row)

        # Return the count as a JSON response
        return jsonify({'total_users': total_users}), 200 # 200 OK
    except sqlite3.Error as e:
        # Handle database errors
        print(f"Database error in get_total_users_count: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500 # 500 Internal Server Error
    except Exception as e:
        print(f"An unexpected error occurred in get_total_users_count: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close() # Ensure connection is closed

# --- NEW ENDPOINT TO COUNT PENDING FEEDBACKS ---
@app.route('/api/feedbacks/pending/count', methods=['GET'])
def get_pending_feedbacks_count():
    """
    API endpoint to get the count of feedbacks with status 'Pending'.
    Returns:
        JSON response with 'pending_feedbacks' count or an error message.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM Feedback WHERE status = 'Pending'")
        pending_feedbacks = cursor.fetchone()[0]
        return jsonify({'pending_feedbacks': pending_feedbacks}), 200
    except sqlite3.Error as e:
        print(f"Database error in get_pending_feedbacks_count: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_pending_feedbacks_count: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

# --- NEW ENDPOINT TO COUNT GENERATED REPORTS ---
@app.route('/api/reports/count', methods=['GET'])
def get_reports_count():
    """
    API endpoint to get the total count of reports generated.
    Returns:
        JSON response with 'reports_generated' count or an error message.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM Report")
        reports_generated = cursor.fetchone()[0]
        return jsonify({'reports_generated': reports_generated}), 200
    except sqlite3.Error as e:
        print(f"Database error in get_reports_count: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_reports_count: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/users/<user_id>/role', methods=['PUT'])
def update_user_role(user_id):
    """
    API endpoint to update a user's role.
    Requires admin_user_id and new_role in the request body.
    Prevents an admin from changing their own role.
    """
    data = request.get_json()
    admin_user_id = data.get('admin_user_id') # In a real app, this comes from a session/JWT
    new_role = data.get('new_role') # Expected: 0 (Admin), 1 (User), 2 (Banned)

    if not admin_user_id or new_role is None or not isinstance(new_role, int):
        return jsonify({'error': 'admin_user_id and a valid new_role (0, 1, or 2) are required'}), 400

    if new_role not in [0, 1, 2]:
        return jsonify({'error': 'Invalid role value. Must be 0 (Admin), 1 (User), or 2 (Banned).'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 1. Verify the 'admin_user_id' making the request is actually an admin
        cursor.execute("SELECT role FROM User WHERE user_id = ?", (admin_user_id,))
        requester_role_row = cursor.fetchone()
        if not requester_role_row or requester_role_row['role'] != 0: # 0 for Admin
            return jsonify({'error': 'Unauthorized: Only administrators can change user roles.'}), 403

        # 2. Prevent an admin from changing their own role
        if user_id == admin_user_id:
            return jsonify({'error': 'An administrator cannot change their own role.'}), 403

        # 3. Check if the target user_id exists
        cursor.execute("SELECT user_id FROM User WHERE user_id = ?", (user_id,))
        target_user_exists = cursor.fetchone()
        if not target_user_exists:
            return jsonify({'error': 'User not found.'}), 404

        # 4. Update the user's role
        cursor.execute("UPDATE User SET role = ? WHERE user_id = ?", (new_role, user_id))
        conn.commit()

        return jsonify({'message': f'User {user_id} role updated to {new_role}'}), 200

    except sqlite3.Error as e:
        print(f"Database error in update_user_role: {e}")
        conn.rollback()
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in update_user_role: {e}")
        conn.rollback()
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    """
    API endpoint to delete a user and all associated data.
    Requires admin_user_id in the request body to authorize the action.
    Prevents an admin from deleting another admin or themselves.
    """
    data = request.get_json()
    admin_user_id = data.get('admin_user_id')

    if not admin_user_id:
        return jsonify({'error': 'admin_user_id is required for this operation.'}), 401 # Unauthorized

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # 1. Verify the 'admin_user_id' making the request is actually an admin
        cursor.execute("SELECT role FROM User WHERE user_id = ?", (admin_user_id,))
        requester_role_row = cursor.fetchone()
        if not requester_role_row or requester_role_row['role'] != 0: # 0 for Admin
            return jsonify({'error': 'Unauthorized: Only administrators can delete users.'}), 403

        # 2. Prevent an admin from deleting themselves
        if user_id == admin_user_id:
            return jsonify({'error': 'An administrator cannot delete their own account.'}), 403

        # 3. Check the role of the user to be deleted
        cursor.execute("SELECT role FROM User WHERE user_id = ?", (user_id,))
        user_to_delete_row = cursor.fetchone()
        if not user_to_delete_row:
            return jsonify({'error': 'User not found.'}), 404
        
        if user_to_delete_row['role'] == 0: # If the user to be deleted is an Admin
            return jsonify({'error': 'Cannot delete another administrator account.'}), 403

        # Start a transaction for atomicity
        conn.execute("BEGIN TRANSACTION;")

        # Tables with user_id as foreign key, ordered for dependency
        tables_to_delete_from = [
            "ChatbotInteraction", "Feedback", "FeedbackResponse", "Goal",
            "MealScan", "Notification", "ProgressLog", "Report", "SystemLog", 
            "UserDietPlan", "UserDietPreference", "WorkoutPlan", "VoiceLog", "Profile",
            # RecipeLibrary does not seem to have a direct user_id FK, assuming it's managed differently
            # Reminder might be associated, if so add it here
        ]

        for table in tables_to_delete_from:
            try:
                # Check if the table actually has a user_id column before attempting to delete
                cursor.execute(f"PRAGMA table_info({table});")
                columns = [col[1] for col in cursor.fetchall()]
                if 'user_id' in columns:
                    cursor.execute(f"DELETE FROM {table} WHERE user_id = ?", (user_id,))
                    print(f"Deleted {cursor.rowcount} records from {table} for user {user_id}")
                else:
                    print(f"Table {table} does not have a user_id column. Skipping.")
            except sqlite3.OperationalError as e:
                print(f"Warning: Could not delete from {table}. Table might not exist or column missing: {e}")
                # You might want to raise an error here if you expect all these tables to exist

        # Finally, delete from the User table
        cursor.execute("DELETE FROM User WHERE user_id = ?", (user_id,))
        if cursor.rowcount == 0:
            conn.rollback()
            return jsonify({'error': 'User not found or already deleted.'}), 404

        conn.commit()
        return jsonify({'message': f'User {user_id} and all associated data deleted successfully.'}), 200

    except sqlite3.Error as e:
        print(f"Database error in delete_user: {e}")
        if conn:
            conn.rollback() # Rollback on error
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in delete_user: {e}")
        if conn:
            conn.rollback() # Rollback on unexpected error
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/systemlogs', methods=['GET'])
def get_system_logs():
    """
    API endpoint to retrieve all entries from the SystemLog table.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Fetch all logs, ordered by timestamp descending for most recent first
        cursor.execute("SELECT log_id, user_id, action, timestamp FROM SystemLog ORDER BY timestamp DESC")
        logs = cursor.fetchall()

        log_list = []
        for log in logs:
            log_list.append({
                'log_entry_id': log['log_id'],
                'user_id': log['user_id'],
                'action': log['action'],
                'timestamp': log['timestamp']
            })
        return jsonify(log_list), 200
    except sqlite3.Error as e:
        print(f"Database error in get_system_logs: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_system_logs: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

# NEW: API endpoint to get all feedback
@app.route('/api/feedback', methods=['GET'])
def get_all_feedback():
    """
    API endpoint to retrieve all feedback entries from the Feedback table.
    Can accept 'status' and 'category' query parameters for filtering.
    """
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        status_filter = request.args.get('status')
        category_filter = request.args.get('category')

        query = "SELECT feedback_id, user_id, submitted_at, category, feedback_text, status FROM Feedback WHERE 1=1"
        params = []

        if status_filter:
            query += " AND status = ?"
            params.append(status_filter)
        if category_filter:
            query += " AND category = ?"
            params.append(category_filter)

        query += " ORDER BY submitted_at DESC, feedback_id DESC" # Order by most recent first

        cursor.execute(query, params)
        feedbacks = cursor.fetchall()

        feedback_list = []
        for fb in feedbacks:
            feedback_list.append({
                'feedback_id': fb['feedback_id'],
                'user_id': fb['user_id'],
                'submitted_at': fb['submitted_at'],
                'category': fb['category'],
                'feedback_text': fb['feedback_text'],
                'status': fb['status']
            })
        return jsonify(feedback_list), 200
    except sqlite3.Error as e:
        print(f"Database error in get_all_feedback: {e}")
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_all_feedback: {e}")
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

# NEW: API endpoint to submit feedback
@app.route('/api/feedback', methods=['POST'])
def submit_feedback():
    """
    API endpoint to submit new feedback to the Feedback table.
    """
    data = request.get_json()
    user_id = data.get('user_id')
    category = data.get('category')
    feedback_text = data.get('feedback_text')

    if not all([user_id, category, feedback_text]):
        return jsonify({'error': 'Missing required fields: user_id, category, feedback_text'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        feedback_id = generate_feedback_id()
        submitted_at = datetime.now().strftime('%Y-%m-%d')
        status = "Pending"

        cursor.execute('''
            INSERT INTO Feedback (feedback_id, user_id, submitted_at, category, feedback_text, status)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (feedback_id, user_id, submitted_at, category, feedback_text, status))
        conn.commit()

        return jsonify({
            'message': 'Feedback submitted successfully',
            'feedback_id': feedback_id,
            'submitted_at': submitted_at,
            'status': status
        }), 201 # 201 Created
    except sqlite3.Error as e:
        print(f"Database error in submit_feedback: {e}")
        conn.rollback()
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in submit_feedback: {e}")
        conn.rollback()
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

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

@app.route('/api/analytics/user_engagement', methods=['GET'])
def get_user_engagement_analytics():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Define time ranges for analysis
        now = datetime.now()
        thirty_minutes_ago = now - timedelta(minutes=30)
        twenty_four_hours_ago = now - timedelta(hours=24)
        seven_days_ago = now - timedelta(days=7)

        # 1. Total Logins/Logouts (All time)
        cursor.execute("SELECT action, COUNT(*) as count FROM SystemLog GROUP BY action")
        overall_activity = {row['action']: row['count'] for row in cursor.fetchall()}
        total_logins = overall_activity.get('Logged In', 0)
        total_logouts = overall_activity.get('Logged Out', 0)

        # 2. Logins/Logouts in last 30 minutes
        cursor.execute(
            "SELECT action, COUNT(*) as count FROM SystemLog WHERE timestamp >= ? GROUP BY action",
            (thirty_minutes_ago.strftime("%Y-%m-%d %H:%M:%S"),)
        )
        last_30_min_activity = {row['action']: row['count'] for row in cursor.fetchall()}
        logins_last_30_minutes = last_30_min_activity.get('Logged In', 0)
        logouts_last_30_minutes = last_30_min_activity.get('Logged Out', 0)

        # 3. Logins/Logouts in last 24 hours
        cursor.execute(
            "SELECT action, COUNT(*) as count FROM SystemLog WHERE timestamp >= ? GROUP BY action",
            (twenty_four_hours_ago.strftime("%Y-%m-%d %H:%M:%S"),)
        )
        last_24_hours_activity = {row['action']: row['count'] for row in cursor.fetchall()}
        logins_last_24_hours = last_24_hours_activity.get('Logged In', 0)
        logouts_last_24_hours = last_24_hours_activity.get('Logged Out', 0)

        # 4. Logins/Logouts in last 7 days
        cursor.execute(
            "SELECT action, COUNT(*) as count FROM SystemLog WHERE timestamp >= ? GROUP BY action",
            (seven_days_ago.strftime("%Y-%m-%d %H:%M:%S"),)
        )
        last_7_days_activity = {row['action']: row['count'] for row in cursor.fetchall()}
        logins_last_7_days = last_7_days_activity.get('Logged In', 0)
        logouts_last_7_days = last_7_days_activity.get('Logged Out', 0)


        # 5. Unique Users Logged In (last 24 hours, last 7 days, overall)
        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM SystemLog WHERE action = 'Logged In' AND timestamp >= ?",
                       (twenty_four_hours_ago.strftime("%Y-%m-%d %H:%M:%S"),))
        unique_users_24h = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM SystemLog WHERE action = 'Logged In' AND timestamp >= ?",
                       (seven_days_ago.strftime("%Y-%m-%d %H:%M:%S"),))
        unique_users_7d = cursor.fetchone()[0]

        cursor.execute("SELECT COUNT(DISTINCT user_id) FROM SystemLog WHERE action = 'Logged In'")
        unique_users_overall = cursor.fetchone()[0]

        # 6. Top N Users by Login Count (e.g., top 5 overall)
        cursor.execute("""
            SELECT user_id, COUNT(*) as login_count
            FROM SystemLog
            WHERE action = 'Logged In'
            GROUP BY user_id
            ORDER BY login_count DESC
            LIMIT 5
        """)
        top_users_by_logins = [dict(row) for row in cursor.fetchall()]

        # 7. Hourly Login/Logout Trends for the last 24 hours
        hourly_trends = []
        for i in range(24):
            # Calculate the start and end of each hour window, relative to 'now'
            # For 00:00, it's 24 hours ago, for 01:00 it's 23 hours ago, etc.
            # So, hour_start is 23-i hours ago, and hour_end is 22-i hours ago.
            hour_start = now - timedelta(hours=(23 - i))
            hour_end = now - timedelta(hours=(22 - i))
            
            cursor.execute(
                """SELECT action, COUNT(*) as count FROM SystemLog
                   WHERE timestamp >= ? AND timestamp < ?
                   GROUP BY action""",
                (hour_start.strftime("%Y-%m-%d %H:%M:%S"), hour_end.strftime("%Y-%m-%d %H:%M:%S"))
            )
            hourly_data = {row['action']: row['count'] for row in cursor.fetchall()}
            
            hourly_trends.append({
                'hour': hour_start.strftime("%H:00"),
                'logins': hourly_data.get('Logged In', 0),
                'logouts': hourly_data.get('Logged Out', 0)
            })

        # 8. Daily Login/Logout Trends for the last 7 days
        daily_trends = []
        for i in range(7):
            day = now - timedelta(days=(6 - i))
            day_start = datetime(day.year, day.month, day.day, 0, 0, 0)
            day_end = datetime(day.year, day.month, day.day, 23, 59, 59)

            cursor.execute(
                """SELECT action, COUNT(*) as count FROM SystemLog
                   WHERE timestamp >= ? AND timestamp <= ?
                   GROUP BY action""",
                (day_start.strftime("%Y-%m-%d %H:%M:%S"), day_end.strftime("%Y-%m-%d %H:%M:%S"))
            )
            daily_data = {row['action']: row['count'] for row in cursor.fetchall()}

            daily_trends.append({
                'date': day.strftime("%Y-%m-%d"),
                'logins': daily_data.get('Logged In', 0),
                'logouts': daily_data.get('Logged Out', 0)
            })
            
        return jsonify({
            'overall_logins': total_logins,
            'overall_logouts': total_logouts,
            'logins_last_30_minutes': logins_last_30_minutes,
            'logouts_last_30_minutes': logouts_last_30_minutes,
            'logins_last_24_hours': logins_last_24_hours,
            'logouts_last_24_hours': logouts_last_24_hours,
            'logins_last_7_days': logins_last_7_days,
            'logouts_last_7_days': logouts_last_7_days,
            'unique_users_24h': unique_users_24h,
            'unique_users_7d': unique_users_7d,
            'unique_users_overall': unique_users_overall,
            'top_users_by_logins': top_users_by_logins,
            'hourly_trends': hourly_trends,
            'daily_trends': daily_trends,
            'success': True
        }), 200

    except sqlite3.Error as e:
        print(f"Database error in get_user_engagement_analytics: {e}")
        return jsonify({'error': 'Database error', 'message': str(e), 'success': False}), 500
    except Exception as e:
        print(f"An unexpected error occurred in get_user_engagement_analytics: {e}")
        return jsonify({'error': 'Server error', 'message': str(e), 'success': False}), 500
    finally:
        if conn:
            conn.close()

@app.route('/logout', methods=['POST'])
def logout():
    """
    API endpoint for logging user logout activity.
    Expects user_id in the request body.
    """
    data = request.get_json()
    user_id = data.get('user_id')
    formatted_user_id = f"U{user_id:03d}"

    if not user_id:
        return jsonify({'error': 'User ID is required for logout logging'}), 400

    conn = None
    try:
        conn = get_db_connection()
        c = conn.cursor()

        # Log successful logout
        log_id = generate_log_id()
        action = "Logged Out"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        c.execute("INSERT INTO SystemLog (log_id, user_id, action, timestamp) VALUES (?, ?, ?, ?)",
                  (log_id, formatted_user_id, action, timestamp))
        conn.commit()

        return jsonify({'message': 'Logout activity logged successfully', 'success': True}), 200

    except sqlite3.Error as e:
        print(f"Database error logging logout activity: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Database error during logout logging', 'success': False}), 500
    except Exception as e:
        print(f"An unexpected error occurred during logout logging: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Internal server error during logout logging', 'success': False}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/system/disable', methods=['POST'])
def disable_system():
    data = request.get_json()
    admin_user_id = data.get('admin_user_id')
    formatted_admin_user_id = f"U{admin_user_id:03d}"

    if not admin_user_id:
        return jsonify({'error': 'Admin user ID is required'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Verify the 'admin_user_id' making the request is actually an admin
        cursor.execute("SELECT role FROM User WHERE user_id = ?", (formatted_admin_user_id,))
        requester_role_row = cursor.fetchone()
        if not requester_role_row or requester_role_row['role'] != 0: # 0 for Admin
            return jsonify({'error': 'Unauthorized: Only administrators can disable the system.'}), 403

        # Update all users with role 1 to role 3
        cursor.execute("UPDATE User SET role = 3 WHERE role = 1")
        conn.commit()
        return jsonify({'message': 'System disabled: All regular users temporarily set to role 3.'}), 200

    except sqlite3.Error as e:
        print(f"Database error in disable_system: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in disable_system: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/system/enable', methods=['POST'])
def enable_system():
    data = request.get_json()
    admin_user_id = data.get('admin_user_id')
    formatted_admin_user_id = f"U{admin_user_id:03d}"

    if not admin_user_id:
        return jsonify({'error': 'Admin user ID is required'}), 400

    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Verify the 'admin_user_id' making the request is actually an admin
        cursor.execute("SELECT role FROM User WHERE user_id = ?", (formatted_admin_user_id,))
        requester_role_row = cursor.fetchone()
        if not requester_role_row or requester_role_row['role'] != 0: # 0 for Admin
            return jsonify({'error': 'Unauthorized: Only administrators can enable the system.'}), 403

        # Update all users with role 3 back to role 1
        cursor.execute("UPDATE User SET role = 1 WHERE role = 3")
        conn.commit()
        return jsonify({'message': 'System enabled: All temporarily disabled users set back to role 1.'}), 200

    except sqlite3.Error as e:
        print(f"Database error in enable_system: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Database error', 'message': str(e)}), 500
    except Exception as e:
        print(f"An unexpected error occurred in enable_system: {e}")
        if conn:
            conn.rollback()
        return jsonify({'error': 'Server error', 'message': str(e)}), 500
    finally:
        if conn:
            conn.close()

#notifications
@app.route('/notifications/add', methods=['POST'])
def add_notification():
    data = request.get_json()
    user_id = data.get('user_id')
    plan_id = data.get('plan_id')
    notif_type = data.get('type')
    details = data.get('details')

    if not user_id or not notif_type or not details:
        return jsonify({'error': 'Missing required fields'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO notifications (user_id, plan_id, type, details, checked, created_at)
        VALUES (?, ?, ?, ?, 0, datetime('now'))
    """, (user_id, plan_id, notif_type, details))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Notification added successfully'}), 201

@app.route('/notifications/<user_id>', methods=['GET'])
def get_notifications(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT notification_id, user_id, plan_id, type, created_at, checked, details 
        FROM notifications 
        WHERE user_id = ? 
        ORDER BY created_at DESC
    """, (user_id,))
    rows = cursor.fetchall()
    print(f"Fetched notifications for user {user_id}: {rows}")
    conn.close()
    notifications = [{
        "notification_id": row[0],
        "user_id": row[1],
        "plan_id": row[2],
        "type": row[3],
        "created_at": row[4],
        "checked": row[5],
        "details": row[6]  # ✅ Include the message body
    } for row in rows]
    return jsonify(notifications)

@app.route('/notifications/check/<int:notification_id>', methods=['POST'])
def mark_notification_checked(notification_id):
    conn = get_db_connection()
    conn.execute("""
        UPDATE notifications
        SET checked = 1
        WHERE notification_id  = ?
    """, (notification_id,))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Notification marked as checked'})

def check_and_insert_daily_reminders(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    today = datetime.now().strftime('%Y-%m-%d')

    # 1️⃣ Find all plan_ids with workouts scheduled today for this user
    cursor.execute("""
        SELECT DISTINCT wp.plan_id
        FROM WorkoutPlan wp
        JOIN WorkoutPlanExercise wpe ON wp.plan_id = wpe.plan_id
        WHERE wp.user_id = ?
          AND wpe.date = ?
    """, (user_id, today))
    
    due_plans = cursor.fetchall()

    for row in due_plans:
        plan_id = row["plan_id"]

        # 2️⃣ Check if a daily reminder has already been sent for this plan and date
        check = cursor.execute("""
            SELECT 1 FROM notifications
            WHERE user_id = ? AND plan_id = ? AND DATE(created_at) = ? AND type = 'daily reminder'
        """, (user_id, plan_id, today)).fetchone()

        # 3️⃣ If not, insert a reminder
        if not check:
            cursor.execute("""
                INSERT INTO notifications (user_id, plan_id, type, details, created_at, checked)
                VALUES (?, ?, 'daily reminder', ?, datetime('now'), 0)
            """, (
                user_id,
                plan_id,
                f"Don't forget your workout for plan {plan_id} today! 🏋️‍♀️"
            ))
            print(f"✅ Inserted reminder for plan {plan_id}")

    conn.commit()
    conn.close()

#check the daily reminders and overdue exercise
@app.route('/reminders/check/<user_id>', methods=['POST'])
def check_reminders(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    today = datetime.now().strftime('%Y-%m-%d')

    # Fetch all active plans
    cursor.execute('SELECT plan_id, created_at, duration_months FROM WorkoutPlan WHERE user_id = ?', (user_id,))
    plans = cursor.fetchall()

    for plan in plans:
        plan_id = plan['plan_id']
        duration = int(plan['duration_months'])
        start_date = datetime.strptime(plan['created_at'], '%Y-%m-%d %H:%M:%S')
        
        # Check each date from start_date to today
        current_date = start_date
        while current_date.strftime('%Y-%m-%d') <= today:
            formatted_date = current_date.strftime('%Y-%m-%d')

            # Get all exercises for this plan and date
            cursor.execute('''
                SELECT Exercise_ID FROM WorkoutPlanExercise
                WHERE plan_id = ? AND date = ?
            ''', (plan_id, formatted_date))
            exercises = cursor.fetchall()

            for ex in exercises:
                exercise_id = ex['Exercise_ID']

                # Skip if already marked
                cursor.execute('''
                    SELECT 1 FROM ExerciseStatus
                    WHERE user_id = ? AND plan_id = ? AND Exercise_ID = ? AND date = ?
                ''', (user_id, plan_id, exercise_id, formatted_date))
                exists = cursor.fetchone()

                if not exists and formatted_date < today:
                    # Mark as overdue
                    cursor.execute('''
                        INSERT INTO ExerciseStatus (user_id, Exercise_ID, plan_id, date, status)
                        VALUES (?, ?, ?, ?, 'overdue')
                    ''', (user_id, exercise_id, plan_id, formatted_date))

            current_date = current_date.replace(day=current_date.day + 1)

    conn.commit()
    conn.close()
    return jsonify({'message': '✅ Checked daily reminders and marked overdue exercises'}), 200

#daily reminder helper for exercise
def insert_daily_reminder_if_due(user_id, plan_id):
    conn = get_db_connection()
    today = datetime.now().strftime('%Y-%m-%d')

    # Check if a reminder for today already exists
    check = conn.execute("""
        SELECT 1 FROM notifications
        WHERE user_id = ? AND plan_id = ? AND DATE(created_at) = ? AND type = 'daily reminder'
    """, (user_id, plan_id, today)).fetchone()

    if not check:
        conn.execute("""
            INSERT INTO notifications (user_id, plan_id, type, created_at, checked)
            VALUES (?, ?, 'daily reminder', datetime('now'), 0)
        """, (user_id, plan_id))
        conn.commit()

    conn.close()

#admin send notifications
@app.route('/admin/send-notification', methods=['POST'])
def send_admin_notification():
    data = request.get_json()
    notif_type = data.get('type')
    details = data.get('details')

    if notif_type not in ['system update', 'system maintenance'] or not details:
        return jsonify({"error": "Invalid input"}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # Get all users with role = 1 (normal users)
    users = cursor.execute("SELECT user_id FROM User WHERE role = 1").fetchall()
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    for user in users:
        cursor.execute("""
            INSERT INTO notifications (user_id, plan_id, type, details, created_at, checked)
            VALUES (?, NULL, ?, ?, ?, 0)
        """, (user['user_id'], notif_type, details, now))

    conn.commit()
    conn.close()

    return jsonify({"message": f"Notification sent to {len(users)} users."})

@app.route('/admin/feedbacks', methods=['GET'])
def get_all_feedbacks():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Feedback WHERE status IS NULL OR status != 'Responded'")
    rows = cursor.fetchall()
    conn.close()

    feedbacks = [{
        "feedback_id": row["feedback_id"],
        "user_id": row["user_id"],
        "submitted_at": row["submitted_at"],
        "category": row["category"],
        "feedback_text": row["feedback_text"]
    } for row in rows]
    return jsonify(feedbacks)

@app.route('/admin/respond-feedback', methods=['POST'])
def respond_to_feedback():
    data = request.get_json()
    feedback_id = data.get('feedback_id')
    user_id = data.get('user_id')
    response_text = data.get('response_text')

    if not all([feedback_id, user_id, response_text]):
        return jsonify({'error': 'Missing required fields'}), 400

    conn = get_db_connection()
    cursor = conn.cursor()

    # ✅ 1. Insert or Replace into FeedbackResponse
    cursor.execute("""
        INSERT OR REPLACE INTO FeedbackResponse 
        (feedback_id, user_id, response_text, response_date)
        VALUES (?, ?, ?, datetime('now'))
    """, (feedback_id, user_id, response_text))

    # ✅ 2. Update status of Feedback
    cursor.execute("""
        UPDATE Feedback
        SET status = 'Responded'
        WHERE feedback_id = ?
    """, (feedback_id,))

    # ✅ 3. Insert into Notifications table
    notification_details = f"Admin responded to your feedback (ID: {feedback_id}): {response_text}"
    cursor.execute("""
        INSERT INTO notifications (user_id, plan_id, type, details, checked, created_at)
        VALUES (?, NULL, ?, ?, 0, datetime('now'))
    """, (user_id, "Feedback Response", notification_details))

    conn.commit()
    conn.close()

    return jsonify({'message': 'Feedback response and notification added.'}), 201

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
    
app.run(host='0.0.0.0', port=5000, debug=True)
