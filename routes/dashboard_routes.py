from flask import Blueprint
from controllers.dashboard_controller import dashboard, export_data

dashboard_blueprint = Blueprint('dashboard', __name__)

dashboard_blueprint.route('/', methods=['GET'])(dashboard)
dashboard_blueprint.route('/export', methods=['GET'])(export_data)
