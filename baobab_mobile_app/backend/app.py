"""
app.py
------
Baobab Mobile Application backend — application factory.

Wires together: configuration, PostgreSQL database, JWT auth, the model
predictor, the prediction / image / feedback / retrain endpoints, and the
automatic-retraining scheduler.

Run:
    pip install -r requirements.txt
    python scripts/train_initial.py      # once, to create model artifacts
    python app.py                         # starts on http://0.0.0.0:5000
"""
import os
import logging
from flask import Flask, jsonify
from flask_cors import CORS

from config import Config
from database.db import db
from ml.predictor import Predictor

logging.basicConfig(level=logging.INFO)


def create_app(config=Config):
    app = Flask(__name__)
    app.config.from_object(config)
    CORS(app)

    db.init_app(app)
    with app.app_context():
        import database.models  # register models
        db.create_all()

    # Load the ML predictor once and stash it on the app.
    if not os.path.exists(os.path.join(config.MODEL_DIR, 'feature_list.json')):
        raise RuntimeError('Model artifacts not found. Run '
                           '`python scripts/train_initial.py` first.')
    predictor = Predictor(config.MODEL_DIR)
    app.extensions['baobab_predictor'] = predictor
    app.extensions['baobab_config'] = config

    # Blueprints
    from auth.routes import auth_bp
    from routes.predict import predict_bp
    from routes.feedback import feedback_bp
    from routes.retrain import retrain_bp
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(predict_bp, url_prefix='/api')
    app.register_blueprint(feedback_bp, url_prefix='/api')
    app.register_blueprint(retrain_bp, url_prefix='/api')

    @app.route('/api/health')
    def health():
        return jsonify({'status': 'healthy',
                        'models_loaded': len(predictor.models),
                        'features': len(predictor.features)}), 200

    @app.route('/')
    def index():
        return jsonify({'name': 'Baobab Mobile API', 'version': '1.0',
                        'endpoints': ['/api/auth/signup', '/api/auth/login',
                                      '/api/categories', '/api/predict',
                                      '/api/predict/image', '/api/feedback',
                                      '/api/history', '/api/retrain',
                                      '/api/models/status', '/api/health']}), 200

    # Start the periodic auto-retrain scheduler.
    from ml import auto_retrain
    auto_retrain.init_scheduler(app, config, db, predictor)
    return app


app = create_app()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=False)
