"""Central configuration for the Baobab backend."""
import os
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(BASE_DIR, '.env.local'))


class Config:
    # --- security ---
    SECRET_KEY = os.environ.get('BAOBAB_SECRET_KEY', 'change-me-in-production')
    JWT_EXP_HOURS = int(os.environ.get('BAOBAB_JWT_EXP_HOURS', '72'))

    # --- database ---
    SQLALCHEMY_DATABASE_URI = os.environ.get(
        'DATABASE_URL', os.environ.get('BAOBAB_DATABASE_URL', 'postgresql://neondb_owner:npg_qumUw9yArz4Z@ep-withered-meadow-b56e35lp-pooler.c-7.us-east-2.aws.neon.tech/neondb?channel_binding=require&sslmode=require'))
    SQLALCHEMY_ENGINE_OPTIONS = {
        "pool_size": 10,
        "max_overflow": 20,
        "pool_timeout": 30,
    }

    # --- paths ---
    MODEL_DIR = os.path.join(BASE_DIR, 'models')
    DATA_DIR = os.path.join(BASE_DIR, 'data')
    UPLOAD_DIR = os.path.join(BASE_DIR, 'uploads')
    BASE_DATASET = os.path.join(DATA_DIR, 'base_dataset.csv')

    # --- automatic retraining ---
    # A background retrain is triggered for a target once this many new
    # expert-confirmed samples for that target have accumulated.
    RETRAIN_THRESHOLD = int(os.environ.get('BAOBAB_RETRAIN_THRESHOLD', '20'))
    # Also run a scheduled retrain check every N hours (0 disables).
    RETRAIN_INTERVAL_HOURS = int(os.environ.get('BAOBAB_RETRAIN_INTERVAL_HOURS', '24'))

    MAX_CONTENT_LENGTH = 10 * 1024 * 1024  # 10 MB image upload cap
