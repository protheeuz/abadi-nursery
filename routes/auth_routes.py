from flask import Blueprint
from controllers.auth_controller import register, login, get_user, login_view, register_view, logout

auth_blueprint = Blueprint('auth', __name__)

# Mobile routes
auth_blueprint.route('/register', methods=['POST'])(register)
auth_blueprint.route('/login', methods=['POST'])(login)
auth_blueprint.route('/getuser', methods=['GET'])(get_user)

# Web routes
auth_blueprint.route('/web/login', methods=['GET', 'POST'])(login_view)
auth_blueprint.route('/web/register', methods=['GET', 'POST'])(register_view)
auth_blueprint.route('/web/logout', methods=['GET'])(logout)
