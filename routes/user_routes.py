from flask import Blueprint
from controllers.user_controller import getUser, update_user_profile

user_blueprint = Blueprint('user', __name__)

user_blueprint.route('/getuser', methods=['GET'])(getUser)
user_blueprint.route('/update', methods=['PUT'])(update_user_profile)
