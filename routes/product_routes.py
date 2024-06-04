from flask import Blueprint
from extensions import mysql
from controllers import product_controller

product_blueprint = Blueprint('product_blueprint', __name__)

@product_blueprint.route('/all', methods=['GET'])
def get_all_products():
    return product_controller.get_all_products(mysql)

@product_blueprint.route('/add', methods=['POST'])
def add_product():
    return product_controller.add_product(mysql)

@product_blueprint.route('/<int:product_id>', methods=['GET'])
def get_product_by_id(product_id):
    return product_controller.get_product_by_id(product_id, mysql)

@product_blueprint.route('/<int:product_id>', methods=['PUT'])
def update_product(product_id):
    return product_controller.update_product(product_id, mysql)

@product_blueprint.route('/<int:product_id>', methods=['DELETE'])
def delete_product(product_id):
    return product_controller.delete_product(product_id, mysql)
