import os

base_dir = os.path.abspath(os.path.dirname(__file__))

JWT_TOKEN_LOCATION = ['headers', 'query_string']

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', '20caddd6e977e6bc524545cc458dd47c')
    UPLOAD_FOLDER_BOOKINGS = os.path.join(base_dir, 'assets/bookings/')
    UPLOAD_FOLDER_PRODUCTS = os.path.join(base_dir, 'assets/product/')
    UPLOAD_FOLDER_PROFILE = os.path.join(base_dir, 'assets/profile/')
    MYSQL_HOST = 'abadinursery.mysql.pythonanywhere-services.com'
    MYSQL_USER = 'abadinursery'
    MYSQL_PASSWORD = os.getenv('MYSQL_PASSWORD', 'db_abadi')  # Set the actual password in your environment variable or use a default
    MYSQL_DB = 'abadinursery$default'