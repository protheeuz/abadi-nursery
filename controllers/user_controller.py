from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import mysql
import os
from werkzeug.utils import secure_filename

UPLOAD_FOLDER = './assets/profile/'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}


@jwt_required()
def update_user_profile():
    current_user = get_jwt_identity()
    user_id = current_user['id']

    nama_lengkap = request.form.get('nama_lengkap')
    address = request.form.get('address')
    profile_picture = request.files.get('profile_picture')

    if not nama_lengkap or not address:
        return jsonify({"message": "Nama Lengkap & Alamat wajib diisi"}), 400

    cur = mysql.connection.cursor()

    if profile_picture:
        if profile_picture.filename == '':
            return jsonify({"message": "No selected file"}), 400

        if profile_picture and allowed_file(profile_picture.filename):
            filename = secure_filename(profile_picture.filename)
            profile_picture_path = os.path.join(UPLOAD_FOLDER, filename)
            profile_picture.save(profile_picture_path)

            cur.execute("UPDATE users SET profile_picture=%s WHERE id=%s", (filename, user_id))

    cur.execute("UPDATE users SET nama_lengkap=%s, address=%s WHERE id=%s", (nama_lengkap, address, user_id))
    mysql.connection.commit()

    # Ambil data pengguna yang diperbarui
    cur.execute("SELECT id, username, role, nama_lengkap, profile_picture, address FROM users WHERE id = %s", (user_id,))
    user = cur.fetchone()
    cur.close()

    if user:
        base_url = 'http://192.168.20.136:5000/profile/'
        user_data = {
            'id': user[0],
            'username': user[1],
            'role': user[2],
            'nama_lengkap': user[3] if user[3] is not None else '',
            'profile_picture': base_url + user[4] if user[4] is not None and user[4] != '' else '',
            'address': user[5] if user[5] is not None else '',
        }
        return jsonify({"message": "Profil berhasil diperbarui", "user": user_data}), 200
    else:
        return jsonify({"message": "User not found"}), 404


@jwt_required()
def getUser():
    current_user = get_jwt_identity()
    user_id = current_user['id']
    
    cur = mysql.connection.cursor()
    cur.execute("SELECT id, username, role, nama_lengkap, profile_picture, address FROM users WHERE id = %s", (user_id,))
    user = cur.fetchone()
    cur.close()
    
    if user:
        user_data = {
            'id': user[0],
            'username': user[1],
            'role': user[2],
            'nama_lengkap': user[3] if user[3] is not None else '',
            'profile_picture': user[4] if user[4] is not None and user[4] != '' else '',
            'address': user[5] if user[5] is not None else '',
        }
        return jsonify(user_data), 200
    else:
        return jsonify({"message": "User not found"}), 404


def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS



def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
