import pandas as pd
from extensions import mysql

def load_csv_data(filepath):
    data = pd.read_csv(filepath)
    data['waktu'] = pd.to_datetime(data['waktu'], format='%Y%m')
    return data

def load_db_data():
    query = """
    SELECT nama_tanaman, jenis_tanaman, total_quantity AS jumlah_tersewa, 
           CONCAT(tahun, LPAD(bulan, 2, '0')) AS waktu
    FROM aggregated_bookings
    """
    cur = mysql.connection.cursor()
    cur.execute(query)
    result = cur.fetchall()
    cur.close()

    db_data = pd.DataFrame(result, columns=['nama_tanaman', 'jenis_tanaman', 'jumlah_tersewa', 'waktu'])
    db_data['waktu'] = pd.to_datetime(db_data['waktu'], format='%Y%m')
    return db_data

def combine_data(csv_data, db_data):
    combined_data = pd.concat([csv_data, db_data], ignore_index=True)
    return combined_data
