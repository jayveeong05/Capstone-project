from flask import Flask, request, jsonify
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
import sqlite3
import base64


app = Flask(__name__)
CORS(app)

def get_db_connection():
    conn = sqlite3.connect('NextGenFitness.db')
    return conn

def init_db():
    conn = get_db_connection()
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS User
                (user_id Text,
                username TEXT, 
                email Text Unique,
                password TEXT,
                role INTEGER)''')
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

if __name__ == '__main__':
    init_db()
    app.run(debug=True)
