# booking_routes.py
from flask import Blueprint
from controllers import booking_controller

booking_blueprint = Blueprint('booking', __name__)

# Routes
booking_blueprint.route('/book', methods=['POST'])(booking_controller.book_plant)
booking_blueprint.route('/verify/<int:booking_id>', methods=['PUT'])(booking_controller.verify_booking)
booking_blueprint.route('/requests', methods=['GET'])(booking_controller.get_bookings)
booking_blueprint.route('/requests/user', methods=['GET'])(booking_controller.get_bookings_for_user)
booking_blueprint.route('/approve/<int:booking_id>', methods=['PUT'])(booking_controller.approve_booking)
booking_blueprint.route('/reject/<int:booking_id>', methods=['PUT'])(booking_controller.reject_booking)
booking_blueprint.route('/approved/<int:user_id>', methods=['GET'])(booking_controller.get_approved_bookings)
booking_blueprint.route('/approved_user', methods=['GET'])(booking_controller.get_approved_bookings_for_user)

@booking_blueprint.route('/all', methods=['GET'])
def get_all_bookings():
    return booking_controller.get_all_bookings()

@booking_blueprint.route('/<int:booking_id>/status/<string:new_status>', methods=['PUT'])
def update_booking_status(booking_id, new_status):
    return booking_controller.update_booking_status(booking_id, new_status)

@booking_blueprint.route('/pending', methods=['GET'])
def get_pending_bookings():
    return booking_controller.get_pending_bookings()

@booking_blueprint.route('/approved', methods=['GET'])
def get_approved_bookings_admin():
    return booking_controller.get_approved_bookings_admin()

@booking_blueprint.route('/<int:booking_id>/delivery_status/<string:new_status>', methods=['PUT'])
def update_delivery_status(booking_id, new_status):
    return booking_controller.update_delivery_status(booking_id, new_status)

@booking_blueprint.route('/approved/user', methods=['GET'])
def get_user_approved_bookings():
    return booking_controller.get_user_approved_bookings()
