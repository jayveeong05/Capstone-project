from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import sqlite3
import base64
import uuid
import re # Import the re module for regex

app = Flask(__name__)
CORS(app)

def get_db_connection():
    conn = sqlite3.connect('backend/NextGenFitness.db')
    conn.row_factory = sqlite3.Row
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

if __name__ == '__main__':
    init_db()
    app.run(debug=True, port=5000)