from flask import render_template, jsonify, send_file, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import mysql
import pandas as pd
import io
import xlsxwriter

ITEMS_PER_PAGE = 15

@jwt_required(locations=["cookies"])
def dashboard():
    current_user = get_jwt_identity()
    
    page = request.args.get('page', 1, type=int)

    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT 
            bookings.id,
            users.username as nama_penyewa,
            bookings.start_date,
            bookings.end_date,
            IFNULL(produk_tanaman.nama_tanaman, 'N/A') as nama_tanaman,
            IFNULL(produk_tanaman.jenis_tanaman, 'N/A') as jenis_tanaman,
            bookings.status
        FROM 
            bookings
        JOIN 
            users ON bookings.user_id = users.id
        LEFT JOIN 
            produk_tanaman ON bookings.id = produk_tanaman.id
        ORDER BY bookings.start_date DESC
        LIMIT %s OFFSET %s
    """, (ITEMS_PER_PAGE, (page - 1) * ITEMS_PER_PAGE))
    rentals = cur.fetchall()
    cur.close()

    cur = mysql.connection.cursor()
    cur.execute("SELECT COUNT(*) FROM bookings")
    total_items = cur.fetchone()[0]
    cur.close()

    cur = mysql.connection.cursor()
    cur.execute("SELECT COUNT(DISTINCT nama_tanaman, jenis_tanaman) FROM produk_tanaman")
    total_tanaman = cur.fetchone()[0]
    cur.close()

    cur = mysql.connection.cursor()
    cur.execute("SELECT COUNT(*) FROM bookings WHERE status = 'approved'")
    total_tersewa = cur.fetchone()[0]
    cur.close()

    cur = mysql.connection.cursor()
    cur.execute("SELECT AVG(total_sewa) FROM bookings WHERE status = 'approved'")
    rata_rata_penyewaan = cur.fetchone()[0]
    cur.close()

    total_pages = (total_items + ITEMS_PER_PAGE - 1) // ITEMS_PER_PAGE

    rental_chart_data_raw = pd.DataFrame(rentals, columns=['id', 'nama_penyewa', 'start_date', 'end_date', 'nama_tanaman', 'jenis_tanaman', 'status'])
    rental_chart_data_raw['bulan'] = pd.to_datetime(rental_chart_data_raw['start_date']).dt.strftime('%B %Y')

    rental_chart_data = {
        "labels": rental_chart_data_raw['bulan'].tolist(),
        "data": rental_chart_data_raw.groupby('bulan').size().tolist()
    }

    return render_template('dashboard.html', 
                           rentals=rentals, 
                           rental_chart_data=rental_chart_data, 
                           page=page, 
                           total_pages=total_pages, 
                           total_tanaman=total_tanaman, 
                           total_tersewa=total_tersewa, 
                           rata_rata_penyewaan=rata_rata_penyewaan, 
                           current_user=current_user)

@jwt_required(locations=["cookies"])
def export_data():
    cur = mysql.connection.cursor()
    cur.execute("""
        SELECT 
            bookings.id,
            users.username as nama_penyewa,
            bookings.start_date,
            bookings.end_date,
            IFNULL(produk_tanaman.nama_tanaman, 'N/A') as nama_tanaman,
            IFNULL(produk_tanaman.jenis_tanaman, 'N/A') as jenis_tanaman,
            bookings.status
        FROM 
            bookings
        JOIN 
            users ON bookings.user_id = users.id
        LEFT JOIN 
            produk_tanaman ON bookings.id = produk_tanaman.id
    """)
    rentals = cur.fetchall()
    cur.close()

    output = io.BytesIO()
    workbook = xlsxwriter.Workbook(output, {'in_memory': True})
    worksheet = workbook.add_worksheet()

    headers = ['ID', 'Nama Penyewa', 'Start Date', 'End Date', 'Nama Tanaman', 'Jenis Tanaman', 'Status']
    for col_num, header in enumerate(headers):
        worksheet.write(0, col_num, header)

    for row_num, rental in enumerate(rentals, start=1):
        for col_num, value in enumerate(rental):
            worksheet.write(row_num, col_num, value)

    workbook.close()
    output.seek(0)

    return send_file(output, download_name="mathtech-data_penyewaan_abadi.xlsx", as_attachment=True, mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
