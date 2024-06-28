# CREATE TABLE IF NOT EXISTS users (
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     username VARCHAR(50) NOT NULL,
#     password VARCHAR(255) NOT NULL,
#     role ENUM('admin', 'penyewa') NOT NULL DEFAULT 'penyewa',
#     nama_lengkap VARCHAR(100) NOT NULL,
#     profile_picture VARCHAR(255),
#     address TEXT
# );

# CREATE TABLE IF NOT EXISTS bookings (
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     user_id INT NOT NULL,
#     start_date DATE NOT NULL,
#     end_date DATE NOT NULL,
#     proof_of_payment VARCHAR(255),
#     status ENUM('pending', 'verified', 'approved', 'rejected') NOT NULL DEFAULT 'pending',
#     total_sewa DECIMAL(10, 2) NOT NULL,
#     need_delivery BOOLEAN NOT NULL DEFAULT FALSE,
#     status_pengiriman ENUM('Belum dikirim', 'Dalam pengiriman', 'Dikirim') DEFAULT 'Belum dikirim',
#     FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
# );

# CREATE TABLE IF NOT EXISTS booking_details (
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     booking_id INT NOT NULL,
#     plant_id INT NOT NULL,
#     nama_tanaman VARCHAR(100) NOT NULL,
#     jenis_tanaman VARCHAR(100) NOT NULL,
#     harga_satuan DECIMAL(10, 2) NOT NULL,
#     quantity INT NOT NULL,
#     total_sewa DECIMAL(10, 2) NOT NULL,
#     FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE
# );

# CREATE TABLE IF NOT EXISTS produk_tanaman (
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     nama_tanaman VARCHAR(100) NOT NULL,
#     jenis_tanaman VARCHAR(100) NOT NULL,
#     harga_sewa DECIMAL(10, 2) NOT NULL,
#     foto_tanaman VARCHAR(255) NOT NULL,
#     jumlah_stok INT NOT NULL
# );

# CREATE TABLE IF NOT EXISTS aggregated_bookings (
#     id INT AUTO_INCREMENT PRIMARY KEY,
#     nama_tanaman VARCHAR(100) NOT NULL,
#     jenis_tanaman VARCHAR(100) NOT NULL,
#     quantity INT NOT NULL,
#     bulan INT NOT NULL,
#     tahun INT NOT NULL,
#     UNIQUE(nama_tanaman, jenis_tanaman, bulan, tahun)
# );