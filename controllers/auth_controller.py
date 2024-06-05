from flask import request, jsonify, render_template, redirect, url_for, flash
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required, set_access_cookies, unset_jwt_cookies
from werkzeug.security import generate_password_hash, check_password_hash
from extensions import mysql

def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    nama_lengkap = data.get('nama_lengkap')
    role = 'penyewa'

    hashed_password = generate_password_hash(password)

    cur = mysql.connection.cursor()
    cur.execute("INSERT INTO users (username, password, role, nama_lengkap) VALUES (%s, %s, %s, %s)",
                (username, hashed_password, role, nama_lengkap))
    mysql.connection.commit()
    cur.close()
    
    return jsonify({"message": "User berhasil ditambahkan"}), 201
    
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM users WHERE username = %s", (username,))
    user = cur.fetchone()
    cur.close()

    if user and check_password_hash(user[2], password):
        access_token = create_access_token(identity={'id': user[0], 'username': user[1], 'role': user[3], 'nama_lengkap': user[4]})
        user_data = {
            'id': user[0],
            'username': user[1],
            'role': user[3],
            'nama_lengkap': user[4]
        }
        response = jsonify({
            "status": "success",
            "access_token": access_token,
            "user": user_data
        })
        set_access_cookies(response, access_token)
        return response, 200
        
    return jsonify({"message": "Username atau Password salah!"}), 401

@jwt_required(locations=["cookies"])
def get_user():
    current_user = get_jwt_identity()
    user_id = current_user['id']
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM users WHERE id = %s", (user_id,))
    user = cur.fetchone()
    cur.close()
    
    if user:
        user_data = {
            'id': user[0],
            'username': user[1],
            'role': user[3],
            'nama_lengkap': user[4]
        }
        return jsonify(user_data), 200
    return jsonify({"message": "User not found"}), 404

def login_view():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']

        cur = mysql.connection.cursor()
        cur.execute("SELECT * FROM users WHERE username = %s", (username,))
        user = cur.fetchone()
        cur.close()

        if user and check_password_hash(user[2], password):
            access_token = create_access_token(identity={'id': user[0], 'username': user[1], 'role': user[3], 'nama_lengkap': user[4]})
            response = redirect(url_for('dashboard.dashboard'))
            set_access_cookies(response, access_token)
            return response
        else:
            flash('Username atau Password salah!')
            return redirect(url_for('auth.login_view'))

    return render_template('auth.html', form_type='login')


def register_view():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']
        nama_lengkap = request.form['nama_lengkap']

        hashed_password = generate_password_hash(password)

        cur = mysql.connection.cursor()
        cur.execute("INSERT INTO users (username, password, role, nama_lengkap) VALUES (%s, %s, %s, %s)", 
                    (username, hashed_password, 'penyewa', nama_lengkap))
        mysql.connection.commit()
        cur.close()

        flash('User berhasil ditambahkan!')
        return redirect(url_for('auth.login_view'))

    return render_template('auth.html', form_type='register')

@jwt_required(locations=["cookies"])
def logout():
    response = redirect(url_for('auth.login_view'))
    unset_jwt_cookies(response)
    return response
