from flask import Flask, render_template, send_from_directory
from flask_mysqldb import MySQL
from config import Config
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from datetime import timedelta

app = Flask(__name__)
app.config.from_object(Config)

app.config['JWT_TOKEN_LOCATION'] = ['headers', 'cookies']
app.config['JWT_COOKIE_SECURE'] = False  # Atur ke True jika menggunakan HTTPS
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(days=30)
app.config['UPLOAD_FOLDER_BOOKINGS'] = './assets/bookings/'
app.config['UPLOAD_FOLDER_PRODUCTS'] = './assets/product/'
app.config['UPLOAD_FOLDER_PROFILE'] = './assets/profile/'

mysql = MySQL(app)
jwt = JWTManager(app)
CORS(app)

# Rute untuk melayani file gambar
@app.route('/bookings/<filename>')
def uploaded_file_bookings(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER_BOOKINGS'], filename)

@app.route('/products/<filename>')
def uploaded_file_products(filename):
    print(f"Requesting file: {filename}") 
    return send_from_directory(app.config['UPLOAD_FOLDER_PRODUCTS'], filename)

@app.route('/profile/<filename>')
def uploaded_file_profile(filename):
    return send_from_directory(app.config['UPLOAD_FOLDER_PROFILE'], filename)

# Daftarkan blueprint
from routes.product_routes import product_blueprint
from routes.booking_routes import booking_blueprint
from routes.auth_routes import auth_blueprint
from routes.user_routes import user_blueprint
from routes.dashboard_routes import dashboard_blueprint
from routes.prediction_routes import prediction_blueprint

app.register_blueprint(auth_blueprint, url_prefix='/auth')
app.register_blueprint(booking_blueprint, url_prefix='/bookings')
app.register_blueprint(product_blueprint, url_prefix='/products')
app.register_blueprint(user_blueprint, url_prefix='/user')
app.register_blueprint(dashboard_blueprint, url_prefix='/dashboard')
app.register_blueprint(prediction_blueprint, url_prefix='/prediction')

@app.route('/')
def index():
    return render_template('auth.html', form_type='login')

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)