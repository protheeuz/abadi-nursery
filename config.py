import os

JWT_TOKEN_LOCATION = ['headers', 'query_string']

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', '20caddd6e977e6bc524545cc458dd47c')
    UPLOAD_FOLDER = './assets/bookings/'
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = ''
    MYSQL_DB = 'db_abadigreen'