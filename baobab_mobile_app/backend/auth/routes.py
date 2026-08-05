"""
auth/routes.py
--------------
Sign-up, login and JWT protection. Passwords are hashed with Werkzeug;
tokens are signed with the app SECRET_KEY.
"""
import datetime
from functools import wraps
import jwt
from flask import Blueprint, request, jsonify, current_app

from database.db import db
from database.models import User

auth_bp = Blueprint('auth', __name__)


def _make_token(user):
    payload = {
        'sub': str(user.id),
        'email': user.email,
        'role': user.role,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(
            hours=current_app.config['JWT_EXP_HOURS']),
        'iat': datetime.datetime.utcnow(),
    }
    return jwt.encode(payload, current_app.config['SECRET_KEY'], algorithm='HS256')


def token_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get('Authorization', '')
        if not auth.startswith('Bearer '):
            print('token_required failed: missing header')
            return jsonify({'error': 'Missing or invalid Authorization header'}), 401
        token = auth.split(' ', 1)[1].strip()
        try:
            data = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
        except jwt.ExpiredSignatureError:
            print('token_required failed: expired')
            return jsonify({'error': 'Token expired'}), 401
        except jwt.InvalidTokenError as e:
            print('token_required failed: invalid', e)
            return jsonify({'error': 'Invalid token'}), 401
        user = User.query.get(data['sub'])
        if not user:
            print('token_required failed: user not found', data['sub'])
            return jsonify({'error': 'User not found'}), 401
        return f(user, *args, **kwargs)
    return wrapper


@auth_bp.route('/signup', methods=['POST'])
def signup():
    data = request.get_json(silent=True) or {}
    name = (data.get('full_name') or '').strip()
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    if not name or not email or not password:
        return jsonify({'error': 'full_name, email and password are required'}), 400
    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters'}), 400
    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'An account with this email already exists'}), 409
    # Determine role efficiently: first user becomes admin, otherwise regular user.
    role = 'admin' if User.query.first() is None else 'user'
    user = User(full_name=name, email=email, role=role)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    return jsonify({'message': 'Account created', 'token': _make_token(user),
                    'user': user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''
    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({'error': 'Invalid email or password'}), 401
    return jsonify({'message': 'Login successful', 'token': _make_token(user),
                    'user': user.to_dict()}), 200


@auth_bp.route('/me', methods=['GET'])
@token_required
def me(user):
    return jsonify({'user': user.to_dict()}), 200
