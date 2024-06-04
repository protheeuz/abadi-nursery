from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), nullable=False)
    nama_lengkap = db.Column(db.String(255), nullable=True)
    profile_picture = db.Column(db.String(255), nullable=True)
    address = db.Column(db.String(255), nullable=True)

class Booking(db.Model):
    __tablename__ = 'bookings'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    proof_of_payment = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(50), nullable=False, default='pending')
    total_sewa = db.Column(db.Float, nullable=False)
    need_delivery = db.Column(db.Boolean, nullable=False, default=False)
    status_pengiriman = db.Column(db.String(50), nullable=False, default='Belum dikirim')
    user = db.relationship('User', back_populates='bookings')
    details = db.relationship('BookingDetail', back_populates='booking')

class BookingDetail(db.Model):
    __tablename__ = 'booking_details'

    id = db.Column(db.Integer, primary_key=True)
    booking_id = db.Column(db.Integer, db.ForeignKey('bookings.id'), nullable=False)
    plant_id = db.Column(db.Integer, nullable=False)
    nama_tanaman = db.Column(db.String(255), nullable=False)
    jenis_tanaman = db.Column(db.String(255), nullable=False)
    harga_satuan = db.Column(db.Float, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    total_sewa = db.Column(db.Float, nullable=False)
    booking = db.relationship('Booking', back_populates='details')

class AggregatedBooking(db.Model):
    __tablename__ = 'aggregated_bookings'

    id = db.Column(db.Integer, primary_key=True)
    nama_tanaman = db.Column(db.String(255), nullable=False)
    jenis_tanaman = db.Column(db.String(255), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    month = db.Column(db.Integer, nullable=False)
    year = db.Column(db.Integer, nullable=False)
