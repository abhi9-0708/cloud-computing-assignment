#!/bin/bash
# Update the system and install necessary packages
sudo apt update -y
sudo apt install -y python3 python3-venv python3-pip mysql-client
sudo rm /usr/lib/python3.12/EXTERNALLY-MANAGED

# Create a project directory
mkdir -p /home/ubuntu/flask_app
cd /home/ubuntu/flask_app

# Install required Python packages
sudo pip install Flask mysql-connector-python

# Create the Flask app (app.py)
cat <<EOL > /home/ubuntu/flask_app/app.py
import os
from flask import Flask, render_template, request, redirect, url_for, flash
import mysql.connector
from mysql.connector import Error

app = Flask(__name__)
app.secret_key = os.urandom(24)

# MySQL Configuration
db_config = {
    'host': 'database-1.czc644mkuw1c.ap-south-1.rds.amazonaws.com',
    'user': 'admin',
    'password': 'password',
    'database': 'feedback'
}

def create_connection():
    try:
        connection = mysql.connector.connect(**db_config)
        return connection
    except Error as e:
        print(f"Error connecting to MySQL: {e}")
        return None

def create_table():
    try:
        connection = create_connection()
        cursor = connection.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS feedback (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                email VARCHAR(100) NOT NULL,
                message TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        connection.commit()
    except Error as e:
        print(f"Error creating table: {e}")
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/submit_feedback', methods=['POST'])
def submit_feedback():
    if request.method == 'POST':
        name = request.form['name']
        email = request.form['email']
        message = request.form['message']

        try:
            connection = create_connection()
            cursor = connection.cursor()
            query = "INSERT INTO feedback (name, email, message) VALUES (%s, %s, %s)"
            values = (name, email, message)
            cursor.execute(query, values)
            connection.commit()
            flash('Feedback submitted successfully!', 'success')
        except Error as e:
            print(f"Error inserting feedback: {e}")
            flash('An error occurred. Please try again.', 'error')
        finally:
            if connection.is_connected():
                cursor.close()
                connection.close()

    return redirect(url_for('index'))

@app.route('/all_feedbacks')
def all_feedbacks():
    try:
        connection = create_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute("SELECT * FROM feedback ORDER BY created_at DESC")
        feedbacks = cursor.fetchall()
        return render_template('all_feedbacks.html', feedbacks=feedbacks)
    except Error as e:
        print(f"Error fetching feedbacks: {e}")
        flash('An error occurred while fetching feedbacks.', 'error')
        return redirect(url_for('index'))
    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

if __name__ == '__main__':
    create_table()
    app.run(debug=True,port=80,host="0.0.0.0")
EOL

# Create the HTML template for the index page (index.html)
mkdir -p /home/ubuntu/flask_app/templates
cat <<EOL > /home/ubuntu/flask_app/templates/index.html
<<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Feedback Form</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        form {
            display: flex;
            flex-direction: column;
        }
        input, textarea {
            margin-bottom: 10px;
            padding: 5px;
        }
        button {
            padding: 10px;
            background-color: #4CAF50;
            color: white;
            border: none;
            cursor: pointer;
        }
        .flash-message {
            padding: 10px;
            margin-bottom: 10px;
            border-radius: 5px;
        }
        .success {
            background-color: #dff0d8;
            border-color: #d6e9c6;
            color: #3c763d;
        }
        .error {
            background-color: #f2dede;
            border-color: #ebccd1;
            color: #a94442;
        }
    </style>
</head>
<body>
    <h1>Feedback Form</h1>
    
    {% with messages = get_flashed_messages(with_categories=true) %}
        {% if messages %}
            {% for category, message in messages %}
                <div class="flash-message {{ category }}">{{ message }}</div>
            {% endfor %}
        {% endif %}
    {% endwith %}

    <form action="{{ url_for('submit_feedback') }}" method="POST">
        <input type="text" name="name" placeholder="Your Name" required>
        <input type="email" name="email" placeholder="Your Email" required>
        <textarea name="message" placeholder="Your Feedback" rows="5" required></textarea>
        <button type="submit">Submit Feedback</button>
    </form>
    <p><a href="{{ url_for('all_feedbacks') }}">View All Feedbacks</a></p>
</body>
</html>
EOL



cat <<EOL > /home/ubuntu/flask_app/templates/all_feedbacks.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>All Feedbacks</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .flash-message {
            padding: 10px;
            margin-bottom: 10px;
            border-radius: 5px;
        }
        .error {
            background-color: #f2dede;
            border-color: #ebccd1;
            color: #a94442;
        }
    </style>
</head>
<body>
    <h1>All Feedbacks</h1>
    
    {% with messages = get_flashed_messages(with_categories=true) %}
        {% if messages %}
            {% for category, message in messages %}
                <div class="flash-message {{ category }}">{{ message }}</div>
            {% endfor %}
        {% endif %}
    {% endwith %}

    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Name</th>
                <th>Email</th>
                <th>Message</th>
                <th>Created At</th>
            </tr>
        </thead>
        <tbody>
            {% for feedback in feedbacks %}
            <tr>
                <td>{{ feedback.id }}</td>
                <td>{{ feedback.name }}</td>
                <td>{{ feedback.email }}</td>
                <td>{{ feedback.message }}</td>
                <td>{{ feedback.created_at }}</td>
            </tr>
            {% endfor %}
        </tbody>
    </table>
    
    <p><a href="{{ url_for('index') }}">Back to Feedback Form</a></p>
</body>
</html>
EOL


# Wait for the RDS MySQL database to be available before attempting to connect and create the feedback database.
while ! mysql -h database-1.czc644mkuw1c.ap-south-1.rds.amazonaws.com -u admin -ppassword -e "exit"; do
    echo "Waiting for the MySQL database..."
    sleep 10
done

# Create the feedback database
mysql -h database-1.czc644mkuw1c.ap-south-1.rds.amazonaws.com -u admin -ppassword -e "CREATE DATABASE IF NOT EXISTS feedback;"

# Run the Flask app
sudo python3 app.py