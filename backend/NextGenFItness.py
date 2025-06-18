from flask import Flask, request, jsonify,send_from_directory
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import sqlite3
import base64
import uuid
import re # Import the re module for regeximport os
import json
import random

app = Flask(__name__)
CORS(app)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
EXERCISE_FOLDER = os.path.join(BASE_DIR, 'exercises')
IMAGE_DIR = EXERCISE_FOLDER

def get_db_connection():
    conn = sqlite3.connect('NextGenFitness.db')
    return conn

def init_db():
    conn = get_db_connection()
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
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("SELECT user_id, password FROM User WHERE username = ?", (username,))
    user = c.fetchone()
    c.execute("SELECT user_id, password FROM User WHERE username = ?", (username,))
    user = c.fetchone()
    conn.close()

    if user and check_password_hash(user['password'], password):
        return jsonify({'message': 'Login successful', 'user_id': user['user_id']}), 200
    else:
        return jsonify({'error': 'Invalid username or password'}), 401

@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get('email')

    conn = get_db_connection()
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
    conn = get_db_connection()
    c = conn.cursor()
    c.execute("UPDATE User SET password = ? WHERE email = ?", (hashed_password, email))
    c.execute("UPDATE User SET password = ? WHERE email = ?", (hashed_password, email))
    conn.commit()
    conn.close()

    return jsonify({'message': 'Password has been successfully updated'}), 200

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
    import os

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

@app.route('/generate-plan', methods=['POST'])
def generate_workout_plan():
    data = request.get_json()

    user_id = data.get('user_id')
    level = data.get('level')
    mechanic = data.get('mechanic')
    equipment = data.get('equipment')
    primaryMuscle = data.get('primaryMuscle')
    category = data.get('category')
    duration_months = data.get('duration', 3)

    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400

    # Build dynamic query
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

    total_days = duration_months * 4 * 3
    plan = exercises[:total_days]

    # Group into weeks/days
    plan_by_weeks = {}
    for i in range(0, len(plan), 3):
        week = i // 3 + 1
        plan_by_weeks.setdefault(f'Week {week}', []).extend(plan[i:i + 3])

    # Insert into WorkoutPlan with plan_data
    cur.execute(
        "INSERT INTO WorkoutPlan (user_id, duration_months) VALUES (?, ?)",
        (user_id, duration_months)
    )
    plan_id = cur.lastrowid

    # Insert into WorkoutPlanExercise
    for week_str, exercises_in_week in plan_by_weeks.items():
        week_number = int(week_str.split()[1])
        day_number = 1
        for ex in exercises_in_week:
            cur.execute('''
                INSERT INTO WorkoutPlanExercise (plan_id, exercise_id, week_number, day_number)
                VALUES (?, ?, ?, ?)
            ''', (plan_id, ex['Exercise_ID'], week_number, day_number))
            day_number += 1

    print("Generated plan_id:", plan_id)
    conn.commit()
    conn.close()

    return jsonify({
        'message': 'Workout plan generated and saved',
        'plan_id': plan_id,
        'plan': plan_by_weeks
    })
@app.route('/get-plan/<int:plan_id>')
def get_weeks(plan_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT DISTINCT week_number FROM WorkoutPlanExercise
        WHERE plan_id = ?
        ORDER BY week_number
    ''', (plan_id,))
    
    weeks = cursor.fetchall()
    conn.close()

    week_names = [f"Week {row['week_number']}" for row in weeks]
    return jsonify({'weeks': week_names})

@app.route('/get-plan-weeks/<int:plan_id>', methods=['GET'])
def get_plan_weeks(plan_id):
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT DISTINCT week_number
        FROM WorkoutPlanExercise
        WHERE plan_id = ?
        ORDER BY week_number
    ''', (plan_id,))
    
    weeks = cursor.fetchall()
    conn.close()

    # Convert to "Week 1", "Week 2", ...
    week_list = [f"Week {row['week_number']}" for row in weeks]
    return jsonify({'weeks': week_list})

@app.route('/get-plan-week/<int:plan_id>/<string:week_name>', methods=['GET'])
def get_plan_week(plan_id, week_name):
    conn = get_db_connection()
    cursor = conn.cursor()

    # Extract week number from "Week 1"
    try:
        week_number = int(week_name.replace("Week ", ""))
    except ValueError:
        return jsonify({"error": "Invalid week format"}), 400

    cursor.execute('''
        SELECT w.exercise_id, w.week_number, w.day_number, e.*
        FROM WorkoutPlanExercise w
        JOIN Exercise e ON w.exercise_id = e.Exercise_ID
        WHERE w.plan_id = ? AND w.week_number = ?
        ORDER BY w.day_number
    ''', (plan_id, week_number))

    exercises = cursor.fetchall()
    result = []
    for ex in exercises:
        exercise_dict = dict(ex)
        # Decode instructions
        exercise_dict['instructions'] = [s.strip() for s in exercise_dict['instructions'].split('.') if s.strip()]
        
        # Handle image URLs
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

if __name__ == '__main__':
    init_db()
    app.run(debug=True, port=5000)