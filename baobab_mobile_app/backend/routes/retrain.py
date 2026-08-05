"""
routes/retrain.py
-----------------
Admin controls and transparency for the retraining lifecycle.

  POST /api/retrain          – force a retrain now (admin only)
  GET  /api/models/versions  – audit trail of model versions
  GET  /api/models/status    – current models, accuracies, pending samples
"""
from flask import Blueprint, jsonify, current_app
from functools import wraps

from database.db import db
from database.models import ModelVersion, TrainingSample
from auth.routes import token_required
from ml import auto_retrain

retrain_bp = Blueprint('retrain', __name__)


def admin_required(f):
    @wraps(f)
    def wrapper(user, *args, **kwargs):
        if user.role != 'admin':
            return jsonify({'error': 'Admin privileges required'}), 403
        return f(user, *args, **kwargs)
    return wrapper


@retrain_bp.route('/retrain', methods=['POST'])
@token_required
@admin_required
def retrain(user):
    status = auto_retrain.trigger_if_needed(
        current_app._get_current_object(), current_app.extensions['baobab_config'], db,
        current_app.extensions['baobab_predictor'], force=True)
    return jsonify({'message': 'Retraining requested.', 'status': status}), 202


@retrain_bp.route('/models/versions', methods=['GET'])
@token_required
def versions(user):
    rows = ModelVersion.query.order_by(ModelVersion.created_at.desc()).limit(100).all()
    return jsonify({'versions': [r.to_dict() for r in rows]}), 200


@retrain_bp.route('/models/status', methods=['GET'])
@token_required
def status(user):
    predictor = current_app.extensions['baobab_predictor']
    pending = TrainingSample.query.filter_by(used_for_training=False).count()
    models = {t: {'algorithm': m['best_model'], 'accuracy': m['best_accuracy']}
              for t, m in predictor.metadata.items()}
    return jsonify({'models': models, 'pending_samples': pending,
                    'retrain_threshold': current_app.config['RETRAIN_THRESHOLD']}), 200
