"""
routes/feedback.py
------------------
Turns user/expert confirmation into TrainingSamples that feed automatic
retraining.

  POST /api/feedback   – submit a confirmed observation (features + the
                         labels the user can vouch for). After insertion,
                         the auto-retrain threshold is checked and, if met,
                         a background retrain is launched.
"""
import json
from flask import Blueprint, request, jsonify, current_app

from database.db import db
from database.models import TrainingSample
from auth.routes import token_required
from ml import auto_retrain

feedback_bp = Blueprint('feedback', __name__)

FEATURE_KEYS = ['height_m', 'crown_diameter_m', 'trunk_diameter_m', 'altitude_m',
                'geographic_zone', 'tree_growth_habitat', 'topography',
                'soil_texture', 'farm_cultivated', 'total_parts_used',
                'taste_attribute', 'medicine_use', 'stem_used',
                'plant_use_count', 'parts_used_count', 'total_special_attributes']


def _as_int(v):
    if v is None or v == '':
        return None
    return int(v)


@feedback_bp.route('/feedback', methods=['POST'])
@token_required
def feedback(user):
    data = request.get_json(silent=True) or {}
    feats = data.get('features') or {}
    if not all(feats.get(k) not in (None, '') for k in
               ['height_m', 'crown_diameter_m', 'trunk_diameter_m', 'altitude_m',
                'geographic_zone', 'soil_texture']):
        return jsonify({'error': 'Incomplete feature set for a training sample'}), 400

    labels = data.get('labels') or {}
    sample = TrainingSample(
        user_id=user.id,
        features_json=json.dumps({k: feats.get(k) for k in FEATURE_KEYS}),
        target_food=_as_int(labels.get('food')),
        target_beverage=_as_int(labels.get('beverage')),
        target_medicine=_as_int(labels.get('medicine')),
        target_agronomic=_as_int(labels.get('agronomic')),
    )
    db.session.add(sample)
    db.session.commit()

    status = auto_retrain.trigger_if_needed(
        current_app._get_current_object(), current_app.extensions['baobab_config'], db,
        current_app.extensions['baobab_predictor'])

    return jsonify({'message': 'Feedback recorded. Thank you for improving the model.',
                    'sample_id': sample.id, 'retrain': status}), 201
