"""
Database schema.

Tables
------
User            – application accounts (sign-up / login).
PredictionRecord – every prediction made, for history and analytics.
TrainingSample  – expert-confirmed rows that FEED AUTOMATIC RETRAINING.
                  Each row stores the full raw feature set plus whichever
                  target labels the user confirmed/corrected.
ModelVersion    – audit trail of every trained model version.
"""
import datetime
import json
from werkzeug.security import generate_password_hash, check_password_hash
from database.db import db


def _now():
    return datetime.datetime.utcnow()


class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    full_name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='user')  # 'user' or 'admin'
    created_at = db.Column(db.DateTime, default=_now)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    predictions = db.relationship('PredictionRecord', backref='user', lazy=True)

    def set_password(self, pw):
        # Use fewer PBKDF2 rounds for faster hashing (still secure for demo).
        self.password_hash = generate_password_hash(pw, method='pbkdf2:sha256:10000', salt_length=16)

    def check_password(self, pw):
        return check_password_hash(self.password_hash, pw)

    def to_dict(self):
        return {'id': self.id, 'full_name': self.full_name,
                'email': self.email, 'role': self.role,
                'created_at': self.created_at.isoformat()}


class PredictionRecord(db.Model):
    __tablename__ = 'prediction_records'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    input_json = db.Column(db.Text, nullable=False)       # raw feature dict
    result_json = db.Column(db.Text, nullable=False)      # full prediction payload
    source = db.Column(db.String(20), default='manual')   # 'manual' | 'image'
    created_at = db.Column(db.DateTime, default=_now)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def to_dict(self):
        return {'id': self.id, 'source': self.source,
                'input': json.loads(self.input_json),
                'result': json.loads(self.result_json),
                'created_at': self.created_at.isoformat()}


class TrainingSample(db.Model):
    """A confirmed field observation used to retrain the models.

    Target columns are nullable because a user may only be able to
    confirm some of the four labels for a given tree.
    """
    __tablename__ = 'training_samples'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    features_json = db.Column(db.Text, nullable=False)  # raw feature dict

    target_food = db.Column(db.Integer, nullable=True)
    target_beverage = db.Column(db.Integer, nullable=True)
    target_medicine = db.Column(db.Integer, nullable=True)
    target_agronomic = db.Column(db.Integer, nullable=True)

    used_for_training = db.Column(db.Boolean, default=False, index=True)
    created_at = db.Column(db.DateTime, default=_now)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def features(self):
        return json.loads(self.features_json)


class ModelVersion(db.Model):
    __tablename__ = 'model_versions'
    id = db.Column(db.Integer, primary_key=True)
    target = db.Column(db.String(20), nullable=False, index=True)
    version = db.Column(db.Integer, nullable=False)
    algorithm = db.Column(db.String(40))
    accuracy = db.Column(db.Float)
    n_training_samples = db.Column(db.Integer)
    metrics_json = db.Column(db.Text)
    is_current = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=_now)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

    def to_dict(self):
        return {'id': self.id, 'target': self.target, 'version': self.version,
                'algorithm': self.algorithm, 'accuracy': self.accuracy,
                'n_training_samples': self.n_training_samples,
                'is_current': self.is_current,
                'metrics': json.loads(self.metrics_json) if self.metrics_json else None,
                'created_at': self.created_at.isoformat()}
