"""
routes/predict.py
-----------------
Prediction endpoints:
  GET  /api/categories            – selectable values for dropdowns
  POST /api/predict               – manual feature input -> predictions
  POST /api/predict/image         – image upload -> estimated features
  GET  /api/history               – the user's past predictions
"""
import os, json, uuid
from flask import Blueprint, request, jsonify, current_app

from database.db import db
from database.models import PredictionRecord
from auth.routes import token_required

predict_bp = Blueprint('predict', __name__)

REQUIRED = ['height_m', 'crown_diameter_m', 'trunk_diameter_m', 'altitude_m',
            'geographic_zone', 'tree_growth_habitat', 'topography',
            'soil_texture', 'farm_cultivated']


def _predictor():
    return current_app.extensions['baobab_predictor']


@predict_bp.route('/categories', methods=['GET'])
def categories():
    return jsonify(_predictor().categories()), 200


@predict_bp.route('/predict', methods=['POST'])
@token_required
def predict(user):
    data = request.get_json(silent=True) or {}
    missing = [f for f in REQUIRED if data.get(f) in (None, '')]
    if missing:
        return jsonify({'error': 'Missing required fields', 'fields': missing}), 400
    try:
        for f in ['height_m', 'crown_diameter_m', 'trunk_diameter_m', 'altitude_m']:
            if float(data[f]) <= 0:
                return jsonify({'error': f'{f} must be positive'}), 400
        result = _predictor().predict(data)
    except Exception as e:
        return jsonify({'error': f'Prediction failed: {e}'}), 400

    rec = PredictionRecord(user_id=user.id, input_json=json.dumps(data),
                           result_json=json.dumps(result),
                           source=data.get('source', 'manual'))
    db.session.add(rec)
    db.session.commit()
    result['record_id'] = rec.id
    return jsonify(result), 200


@predict_bp.route('/predict/image', methods=['POST'])
@token_required
def predict_image(user):
    """Estimate morphology from an uploaded image.

    Returns EDITABLE estimates; the client lets the user confirm/adjust
    and add the non-visual descriptors (soil, zone, etc.) before calling
    /predict. Optionally accepts a scale reference for accurate sizing.
    """
    from ml.image_features import extract_features
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided (field name: image)'}), 400
    f = request.files['image']
    if not f.filename:
        return jsonify({'error': 'Empty filename'}), 400

    os.makedirs(current_app.config['UPLOAD_DIR'], exist_ok=True)
    ext = os.path.splitext(f.filename)[1].lower() or '.jpg'
    path = os.path.join(current_app.config['UPLOAD_DIR'], f'{uuid.uuid4().hex}{ext}')
    f.save(path)

    ref_h = request.form.get('ref_object_height_m', type=float)
    ref_px = request.form.get('ref_object_pixel_height', type=float)
    try:
        report = extract_features(path, ref_object_height_m=ref_h,
                                  ref_object_pixel_height=ref_px)
    except Exception as e:
        return jsonify({'error': f'Image analysis failed: {e}'}), 400
    finally:
        try:
            os.remove(path)
        except OSError:
            pass

    return jsonify({
        'success': True,
        'estimated_features': report['estimated'],
        'confidence': report['confidence'],
        'scale_source': report['scale_source'],
        'notes': report['notes'],
        'message': 'Estimated morphology from image. Please confirm or adjust '
                   'the values and select the site descriptors before predicting.',
    }), 200


@predict_bp.route('/history', methods=['GET'])
@token_required
def history(user):
    recs = (PredictionRecord.query.filter_by(user_id=user.id)
            .order_by(PredictionRecord.created_at.desc()).limit(100).all())
    return jsonify({'history': [r.to_dict() for r in recs]}), 200
