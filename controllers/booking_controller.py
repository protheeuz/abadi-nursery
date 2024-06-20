from datetime import date, datetime
from flask import current_app, request, jsonify, send_from_directory
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import mysql
import os
from werkzeug.utils import secure_filename


ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@jwt_required()
def book_plant():
    current_user = get_jwt_identity()
    if current_user['role'] != 'penyewa':
        return jsonify({"message": "Admins cannot book plants"}), 403

    data = request.form
    start_date = data.get('start_date')
    end_date = data.get('end_date')
    need_delivery = data.get('need_delivery', 'false').lower() == 'true'
    total_sewa = data.get('total_sewa')

    if 'proof_of_payment' not in request.files:
        return jsonify({"message": "No file part"}), 400

    proof_of_payment = request.files['proof_of_payment']
    if proof_of_payment.filename == '':
        return jsonify({"message": "No selected file"}), 400

    if proof_of_payment and allowed_file(proof_of_payment.filename):
        proof_of_payment_filename = secure_filename(proof_of_payment.filename)
        proof_of_payment_path = os.path.join(current_app.config['UPLOAD_FOLDER_BOOKINGS'], proof_of_payment_filename)
        
        # Pastikan direktori ada
        os.makedirs(current_app.config['UPLOAD_FOLDER_BOOKINGS'], exist_ok=True)

        proof_of_payment.save(proof_of_payment_path)

        # Ambil semua fields yang diawali dengan "cart_items_"
        cart_items = [value for key, value in data.items() if key.startswith('cart_items_')]
        if not cart_items:
            return jsonify({"message": "Cart is empty"}), 400

        cur = mysql.connection.cursor()

        # Insert into bookings table
        cur.execute("INSERT INTO bookings (user_id, start_date, end_date, proof_of_payment, status, total_sewa, need_delivery, status_pengiriman) VALUES (%s, %s, %s, %s, 'pending', %s, %s, %s)",
                    (current_user['id'], start_date, end_date, proof_of_payment_filename, total_sewa, need_delivery, 'Belum dikirim'))
        booking_id = cur.lastrowid

        # Insert into booking_details table
        for item in cart_items:
            item_data = item.split(',')
            plant_id = item_data[0]
            nama_tanaman = item_data[1]
            jenis_tanaman = item_data[2]
            harga_satuan = item_data[3]
            quantity = item_data[4]
            total_sewa = item_data[5]

            # Periksa apakah plant_id ada di tabel produk_tanaman
            cur.execute("SELECT id FROM produk_tanaman WHERE id = %s", (plant_id,))
            plant_exists = cur.fetchone()
            if not plant_exists:
                return jsonify({"message": f"plant_id {plant_id} does not exist"}), 400

            cur.execute("INSERT INTO booking_details (booking_id, plant_id, nama_tanaman, jenis_tanaman, harga_satuan, quantity, total_sewa) VALUES (%s, %s, %s, %s, %s, %s, %s)",
                        (booking_id, plant_id, nama_tanaman, jenis_tanaman, harga_satuan, quantity, total_sewa))

        mysql.connection.commit()
        cur.close()

        return jsonify({"message": "Booking created successfully"}), 201
    else:
        return jsonify({"message": "Allowed file types are png, jpg, jpeg"}), 400


@jwt_required()
def get_bookings():
    current_user = get_jwt_identity()
    if (current_user['role'] != 'admin'):
        return jsonify({"message": "Only admins can view bookings"}), 403

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM bookings")
    bookings = cur.fetchall()
    cur.close()

    return jsonify(bookings), 200

@jwt_required()
def get_bookings_for_user():
    current_user = get_jwt_identity()

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM bookings WHERE user_id = %s", (current_user['id'],))
    bookings = cur.fetchall()
    cur.close()

    return jsonify(bookings), 200

@jwt_required()
def verify_booking(booking_id):
    current_user = get_jwt_identity()

    cur = mysql.connection.cursor()
    cur.execute("SELECT role FROM users WHERE id = %s", (current_user,))
    user = cur.fetchone()
    cur.close()

    if user['role'] != 'admin':
        return jsonify({'message': 'Access forbidden, admin only'}), 403

    try:
        cur = mysql.connection.cursor()
        cur.execute("UPDATE bookings SET status = 'verified' WHERE id = %s", (booking_id,))
        mysql.connection.commit()
        cur.close()

        return jsonify({"message": "Booking verified successfully"}), 200
    except Exception as e:
        return jsonify({"message": str(e)}), 500


@jwt_required()
def approve_booking(booking_id):
    current_user = get_jwt_identity()
    if (current_user['role'] != 'admin'):
        return jsonify({"message": "Hanya admin yang bisa menyetujui pemesanan"}), 403

    try:
        cur = mysql.connection.cursor()
        
        # Ambil semua detail pemesanan untuk mengurangi stok
        cur.execute("SELECT plant_id, quantity, nama_tanaman, jenis_tanaman FROM booking_details WHERE booking_id = %s", (booking_id,))
        booking_details = cur.fetchall()

        # Mulai transaksi
        mysql.connection.begin()

        # Kurangi stok untuk setiap item dalam pemesanan dan salin data ke tabel aggregated_bookings
        for detail in booking_details:
            plant_id = detail[0]
            quantity = detail[1]
            nama_tanaman = detail[2]
            jenis_tanaman = detail[3]
            
            # Periksa apakah stok cukup
            cur.execute("SELECT jumlah_stok FROM produk_tanaman WHERE id = %s", (plant_id,))
            stok = cur.fetchone()[0]
            if stok < quantity:
                mysql.connection.rollback()
                return jsonify({"message": f"Stok tidak cukup untuk plant_id {plant_id}"}), 400
            
            cur.execute("UPDATE produk_tanaman SET jumlah_stok = jumlah_stok - %s WHERE id = %s", (quantity, plant_id))

            # Tambahkan ke tabel aggregated_bookings
            now = datetime.now()
            bulan = now.month
            tahun = now.year

            # Periksa apakah entri sudah ada di tabel aggregated_bookings
            cur.execute("""
                SELECT id, quantity FROM aggregated_bookings 
                WHERE nama_tanaman = %s AND jenis_tanaman = %s AND bulan = %s AND tahun = %s
            """, (nama_tanaman, jenis_tanaman, bulan, tahun))
            existing_record = cur.fetchone()

            if existing_record:
                new_quantity = existing_record[1] + quantity
                cur.execute("""
                    UPDATE aggregated_bookings 
                    SET quantity = %s 
                    WHERE id = %s
                """, (new_quantity, existing_record[0]))
            else:
                cur.execute("""
                    INSERT INTO aggregated_bookings (nama_tanaman, jenis_tanaman, quantity, bulan, tahun) 
                    VALUES (%s, %s, %s, %s, %s)
                """, (nama_tanaman, jenis_tanaman, quantity, bulan, tahun))

        # Update status pemesanan menjadi approved
        cur.execute("UPDATE bookings SET status = 'approved' WHERE id = %s", (booking_id,))
        
        # Commit transaksi
        mysql.connection.commit()
        cur.close()

        return jsonify({"message": "Pemesanan disetujui dengan sukses"}), 200
    except Exception as e:
        mysql.connection.rollback()
        print(f"Error approving booking: {e}")
        return jsonify({"message": str(e)}), 500

@jwt_required()
def reject_booking(booking_id):
    current_user = get_jwt_identity()
    if (current_user['role'] != 'admin'):
        return jsonify({"message": "Only admins can reject bookings"}), 403

    cur = mysql.connection.cursor()
    cur.execute("UPDATE bookings SET status = 'rejected' WHERE id = %s", (booking_id,))
    mysql.connection.commit()
    cur.close()

    return jsonify({"message": "Booking rejected successfully"}), 200

@jwt_required()
def get_proof_of_payment(filename):
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can view proof of payment"}), 403

    return send_from_directory(current_app.config['UPLOAD_FOLDER_BOOKINGS'], filename)

@jwt_required()
def get_approved_bookings(user_id):
    current_user = get_jwt_identity()
    if current_user['role'] != 'penyewa' and current_user['role'] != 'admin':
        return jsonify({"message": "Access forbidden"}), 403

    cur = mysql.connection.cursor()
    cur.execute("SELECT * FROM bookings WHERE user_id = %s AND status = 'approved'", (user_id,))
    approved_bookings = cur.fetchall()
    cur.close()

    return jsonify(approved_bookings), 200

@jwt_required()
def get_all_bookings(mysql):
    try:
        cursor = mysql.connection.cursor()
        query = """
        SELECT b.id, b.user_id, u.nama_lengkap, b.start_date, b.end_date, b.proof_of_payment, b.status, b.total_sewa, b.need_delivery, u.address, b.status_pengiriman
        FROM bookings b
        JOIN users u ON b.user_id = u.id;
        """
        cursor.execute(query)
        bookings = cursor.fetchall()
        
        # Log data fetched
        print(f"Bookings fetched: {bookings}")

        all_bookings = []
        for booking in bookings:
            booking_details_query = "SELECT * FROM booking_details WHERE booking_id = %s"
            cursor.execute(booking_details_query, (booking[0],))
            booking_details = cursor.fetchall()
            details = [
                {
                    'id': detail[0],
                    'booking_id': detail[1],
                    'plant_id': detail[2],
                    'nama_tanaman': detail[3],
                    'jenis_tanaman': detail[4],
                    'harga_satuan': float(detail[5]),
                    'quantity': detail[6],
                    'total_sewa': float(detail[7]),
                }
                for detail in booking_details
            ]

            all_bookings.append({
                'id': booking[0],
                'user_id': booking[1],
                'nama_lengkap': booking[2],
                'start_date': booking[3].isoformat() if isinstance(booking[3], (date, datetime)) else booking[3],
                'end_date': booking[4].isoformat() if isinstance(booking[4], (date, datetime)) else booking[4],
                'proof_of_payment': booking[5],
                'status': booking[6],
                'total_sewa': float(booking[7]),
                'need_delivery': booking[8],
                'address': booking[9],
                'status_pengiriman': booking[10], 
                'booking_details': details
            })

        cursor.close()
        return jsonify(all_bookings), 200
    except Exception as e:
        print(f"Error fetching bookings: {e}")
        return jsonify({'message': str(e)}), 500


@jwt_required()
def update_booking_status(booking_id, new_status):
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can update booking status"}), 403

    try:
        cur = mysql.connection.cursor()

        # Update status pemesanan
        cur.execute("UPDATE bookings SET status = %s WHERE id = %s", (new_status, booking_id))

        if new_status == 'approved':
            # Ambil semua detail pemesanan
            cur.execute("""
                SELECT bd.nama_tanaman, bd.jenis_tanaman, bd.quantity, 
                DATE_FORMAT(b.start_date, '%%Y') as year, DATE_FORMAT(b.start_date, '%%m') as month 
                FROM booking_details bd 
                JOIN bookings b ON bd.booking_id = b.id 
                WHERE b.id = %s
            """, (booking_id,))
            booking_details = cur.fetchall()

            for detail in booking_details:
                nama_tanaman = detail[0]
                jenis_tanaman = detail[1]
                quantity = detail[2]
                year = detail[3]
                month = detail[4]

                # Periksa apakah entri sudah ada di tabel aggregated_bookings
                cur.execute("""
                    SELECT id FROM aggregated_bookings 
                    WHERE nama_tanaman = %s AND jenis_tanaman = %s AND bulan = %s AND tahun = %s
                """, (nama_tanaman, jenis_tanaman, month, year))
                aggregated_entry = cur.fetchone()

                if aggregated_entry:
                    cur.execute("UPDATE aggregated_bookings SET quantity = quantity + %s WHERE id = %s", 
                                (quantity, aggregated_entry[0]))
                else:
                    cur.execute("""
                        INSERT INTO aggregated_bookings (nama_tanaman, jenis_tanaman, quantity, bulan, tahun) 
                        VALUES (%s, %s, %s, %s, %s)
                    """, (nama_tanaman, jenis_tanaman, quantity, month, year))

        mysql.connection.commit()
        cur.close()

        return jsonify({"message": "Booking status updated successfully"}), 200
    except Exception as e:
        mysql.connection.rollback()
        print(f"Error updating booking status: {e}")
        return jsonify({"message": str(e)}), 500
    
@jwt_required()
def get_pending_bookings():
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can view bookings"}), 403

    try:
        cur = mysql.connection.cursor()
        query = """
        SELECT b.id, b.user_id, u.nama_lengkap, b.start_date, b.end_date, b.proof_of_payment, b.status, b.total_sewa, b.need_delivery, u.address, b.status_pengiriman
        FROM bookings b
        JOIN users u ON b.user_id = u.id
        WHERE b.status = 'pending';
        """
        cur.execute(query)
        bookings = cur.fetchall()
        cur.close()

        all_bookings = []
        for booking in bookings:
            booking_details_query = "SELECT * FROM booking_details WHERE booking_id = %s"
            cur = mysql.connection.cursor()
            cur.execute(booking_details_query, (booking[0],))
            booking_details = cur.fetchall()
            cur.close()

            details = [
                {
                    'id': detail[0],
                    'booking_id': detail[1],
                    'plant_id': detail[2],
                    'nama_tanaman': detail[3],
                    'jenis_tanaman': detail[4],
                    'harga_satuan': float(detail[5]),
                    'quantity': detail[6],
                    'total_sewa': float(detail[7]),
                }
                for detail in booking_details
            ]

            all_bookings.append({
                'id': booking[0],
                'user_id': booking[1],
                'nama_lengkap': booking[2],
                'start_date': booking[3].isoformat() if isinstance(booking[3], (date, datetime)) else booking[3],
                'end_date': booking[4].isoformat() if isinstance(booking[4], (date, datetime)) else booking[4],
                'proof_of_payment': booking[5],
                'status': booking[6],
                'total_sewa': float(booking[7]),
                'need_delivery': booking[8],
                'address': booking[9],
                'status_pengiriman': booking[10], 
                'booking_details': details
            })

        return jsonify(all_bookings), 200
    except Exception as e:
        print(f"Error fetching bookings: {e}")
        return jsonify({'message': str(e)}), 500

@jwt_required()
def get_approved_bookings_admin():
    current_user = get_jwt_identity()
    if current_user['role'] not in ['admin', 'penyewa']:
        return jsonify({"message": "Only admins and penyewa can view bookings"}), 403
    try:
        cur = mysql.connection.cursor()
        query = """
        SELECT b.id, b.user_id, u.nama_lengkap, b.start_date, b.end_date, b.proof_of_payment, b.status, b.total_sewa, b.need_delivery, u.address, b.status_pengiriman
        FROM bookings b
        JOIN users u ON b.user_id = u.id
        WHERE b.status = 'approved';
        """
        cur.execute(query)
        bookings = cur.fetchall()
        cur.close()

        result = []
        for booking in bookings:
            booking_details_query = "SELECT * FROM booking_details WHERE booking_id = %s"
            cur = mysql.connection.cursor()
            cur.execute(booking_details_query, (booking[0],))
            booking_details = cur.fetchall()
            cur.close()

            details = [
                {
                    'id': detail[0],
                    'booking_id': detail[1],
                    'plant_id': detail[2],
                    'nama_tanaman': detail[3],
                    'jenis_tanaman': detail[4],
                    'harga_satuan': float(detail[5]),
                    'quantity': detail[6],
                    'total_sewa': float(detail[7]),
                }
                for detail in booking_details
            ]

            result.append({
                'id': booking[0],
                'user_id': booking[1],
                'nama_lengkap': booking[2],
                'start_date': booking[3].isoformat() if isinstance(booking[3], (date, datetime)) else booking[3],
                'end_date': booking[4].isoformat() if isinstance(booking[4], (date, datetime)) else booking[4],
                'proof_of_payment': booking[5],
                'status': booking[6],
                'total_sewa': float(booking[7]),
                'need_delivery': booking[8],
                'address': booking[9],
                'status_pengiriman': booking[10], 
                'booking_details': details
            })

        return jsonify(result), 200
    except Exception as e:
        print(f"Error fetching bookings: {e}")
        return jsonify({'message': str(e)}), 500
    
@jwt_required()
def get_approved_bookings_for_user():
    current_user = get_jwt_identity()
    try:
        cur = mysql.connection.cursor()
        query = """
        SELECT b.id, b.user_id, u.nama_lengkap, b.start_date, b.end_date, b.proof_of_payment, b.status, b.total_sewa, b.need_delivery, u.address, b.status_pengiriman
        FROM bookings b
        JOIN users u ON b.user_id = u.id
        WHERE b.status = 'approved' AND b.user_id = %s;
        """
        cur.execute(query, (current_user['id'],))
        bookings = cur.fetchall()
        cur.close()

        result = []
        for booking in bookings:
            booking_details_query = "SELECT * FROM booking_details WHERE booking_id = %s"
            cur = mysql.connection.cursor()
            cur.execute(booking_details_query, (booking[0],))
            booking_details = cur.fetchall()
            cur.close()

            details = [
                {
                    'id': detail[0],
                    'booking_id': detail[1],
                    'plant_id': detail[2],
                    'nama_tanaman': detail[3],
                    'jenis_tanaman': detail[4],
                    'harga_satuan': float(detail[5]),
                    'quantity': detail[6],
                    'total_sewa': float(detail[7]),
                }
                for detail in booking_details
            ]

            result.append({
                'id': booking[0],
                'user_id': booking[1],
                'nama_lengkap': booking[2],
                'start_date': booking[3].isoformat() if isinstance(booking[3], (date, datetime)) else booking[3],
                'end_date': booking[4].isoformat() if isinstance(booking[4], (date, datetime)) else booking[4],
                'proof_of_payment': booking[5],
                'status': booking[6],
                'total_sewa': float(booking[7]),
                'need_delivery': booking[8],
                'address': booking[9],
                'status_pengiriman': booking[10], 
                'booking_details': details
            })
        return jsonify(result), 200
    except Exception as e:
        print(f"Error fetching approved bookings for user: {e}")
        return jsonify({'message': str(e)}), 500

@jwt_required()
def get_user_approved_bookings():
    current_user = get_jwt_identity()
    if current_user['role'] != 'penyewa':
        return jsonify({"message": "Only penyewa can view their approved bookings"}), 403

    try:
        cur = mysql.connection.cursor()
        query = """
        SELECT b.id, b.user_id, u.nama_lengkap, b.start_date, b.end_date, b.proof_of_payment, b.status, b.total_sewa, b.need_delivery, u.address, b.status_pengiriman
        FROM bookings b
        JOIN users u ON b.user_id = u.id
        WHERE b.status = 'approved' AND b.user_id = %s;
        """
        cur.execute(query, (current_user['id'],))
        bookings = cur.fetchall()
        cur.close()

        result = []
        for booking in bookings:
            booking_details_query = "SELECT * FROM booking_details WHERE booking_id = %s"
            cur = mysql.connection.cursor()
            cur.execute(booking_details_query, (booking[0],))
            booking_details = cur.fetchall()
            cur.close()

            details = [
                {
                    'id': detail[0],
                    'booking_id': detail[1],
                    'plant_id': detail[2],
                    'nama_tanaman': detail[3],
                    'jenis_tanaman': detail[4],
                    'harga_satuan': float(detail[5]),
                    'quantity': detail[6],
                    'total_sewa': float(detail[7]),
                }
                for detail in booking_details
            ]

            result.append({
                'id': booking[0],
                'user_id': booking[1],
                'nama_lengkap': booking[2],
                'start_date': booking[3].isoformat() if isinstance(booking[3], (date, datetime)) else booking[3],
                'end_date': booking[4].isoformat() if isinstance(booking[4], (date, datetime)) else booking[4],
                'proof_of_payment': booking[5],
                'status': booking[6],
                'total_sewa': float(booking[7]),
                'need_delivery': booking[8],
                'address': booking[9],
                'status_pengiriman': booking[10], 
                'booking_details': details
            })

        return jsonify(result), 200
    except Exception as e:
        print(f"Error fetching user approved bookings: {e}")
        return jsonify({'message': str(e)}), 500

VALID_STATUSES = ['Belum dikirim', 'Sedang diproses', 'Sedang dikemas', 'Sedang dikirim', 'Sudah sampai']

@jwt_required()
def update_delivery_status(booking_id, new_status):
    current_user = get_jwt_identity()
    if current_user['role'] != 'admin':
        return jsonify({"message": "Only admins can update delivery status"}), 403

    try:
        cur = mysql.connection.cursor()

        # Log query dan parameter untuk debug
        print(f"Received booking ID: {booking_id}")
        print(f"Received new status: {new_status}")

        update_query = "UPDATE bookings SET status_pengiriman = %s WHERE id = %s"
        cur.execute(update_query, (new_status, booking_id))
        mysql.connection.commit()

        # Verifikasi perubahan dengan mengambil baris yang diperbarui
        cur.execute("SELECT status_pengiriman FROM bookings WHERE id = %s", (booking_id,))
        updated_status = cur.fetchone()

        if updated_status:
            print(f"Successfully updated booking ID {booking_id} to status: {updated_status[0]}")
            cur.close()
            return jsonify({"message": "Delivery status updated successfully", "status_pengiriman": updated_status[0]}), 200
        else:
            print(f"Failed to find booking ID {booking_id} after update.")
            cur.close()
            return jsonify({"message": "Failed to update delivery status"}), 400

    except Exception as e:
        mysql.connection.rollback()
        print(f"Error updating delivery status: {e}")
        return jsonify({"message": str(e)}), 500