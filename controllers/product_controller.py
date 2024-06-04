from flask import request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
import os

ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@jwt_required()
def add_product(mysql):
    if 'foto_tanaman' not in request.files:
        return jsonify({"message": "No file part"}), 400

    file = request.files['foto_tanaman']
    if file.filename == '':
        return jsonify({"message": "No selected file"}), 400

    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        upload_folder = current_app.config['UPLOAD_FOLDER_PRODUCTS']
        os.makedirs(upload_folder, exist_ok=True)
        file.save(os.path.join(upload_folder, filename))

        nama_tanaman = request.form['nama_tanaman']
        jenis_tanaman = request.form['jenis_tanaman']
        harga_sewa = request.form['harga_sewa']
        foto_tanaman = os.path.join(upload_folder, filename)  # Simpan path lengkap di database
        jumlah_stok = request.form['jumlah_stok']

        cursor = mysql.connection.cursor()
        cursor.execute(
            "INSERT INTO produk_tanaman (nama_tanaman, jenis_tanaman, harga_sewa, foto_tanaman, jumlah_stok) VALUES (%s, %s, %s, %s, %s)",
            (nama_tanaman, jenis_tanaman, harga_sewa, foto_tanaman, jumlah_stok)
        )
        mysql.connection.commit()
        cursor.close()

        return jsonify({'status': 'success', 'message': 'Product added successfully!'}), 201
    else:
        return jsonify({"message": "Allowed file types are png, jpg, jpeg"}), 400

def get_all_products(mysql):
    try:
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT * FROM produk_tanaman")
        products = cursor.fetchall()
        cursor.close()

        product_list = []
        for product in products:
            product_dict = {
                'id': product[0],
                'nama_tanaman': product[1],
                'jenis_tanaman': product[2],
                'harga_sewa': product[3],
                'foto_tanaman': product[4],
                'jumlah_stok': product[5],
            }
            product_list.append(product_dict)

        return jsonify({'products': product_list}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def get_product_by_id(product_id, mysql):
    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM produk_tanaman WHERE id = %s", (product_id,))
    product = cur.fetchone()
    cur.close()

    if product:
        product_dict = {
            'id': product[0],
            'nama_tanaman': product[1],
            'jenis_tanaman': product[2],
            'harga_sewa': product[3],
            'foto_tanaman': product[4],
            'jumlah_stok': product[5],
        }
        return jsonify(product_dict), 200
    else:
        return jsonify({"message": "Product not found"}), 404

@jwt_required()
def update_product(product_id, mysql):
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can update products"}), 403

    data = request.get_json()
    nama_tanaman = data.get('nama_tanaman')
    jenis_tanaman = data.get('jenis_tanaman')
    harga_sewa = data.get('harga_sewa')
    jumlah_stok = data.get('jumlah_stok')

    cur = mysql.connection.cursor()
    cur.execute("UPDATE produk_tanaman SET nama_tanaman = %s, jenis_tanaman = %s, harga_sewa = %s, jumlah_stok = %s WHERE id = %s",
                (nama_tanaman, jenis_tanaman, harga_sewa, jumlah_stok, product_id))
    mysql.connection.commit()
    cur.close()

    return jsonify({"message": "Product updated successfully"}), 200

@jwt_required()
def delete_product(product_id, mysql):
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can delete products"}), 403

    cur = mysql.connection.cursor()
    cur.execute("DELETE FROM produk_tanaman WHERE id = %s", (product_id,))
    mysql.connection.commit()
    cur.close()

    return jsonify({"message": "Product deleted successfully"}), 200
