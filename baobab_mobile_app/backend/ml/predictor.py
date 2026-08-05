"""
predictor.py
------------
Loads the serialised models, scalers, encoders and feature metadata, and
exposes a thread-safe `predict(raw_input)` used by the API. Supports
hot-reloading after a retrain via `reload()`.
"""
import os, json, pickle, threading
import numpy as np

import pandas as pd

# --- MOVED FROM feature_engineering.py ---
FEATURES = [
    'Height_m', 'Crown_Diameter_m', 'Trunk_Diameter_m', 'Altitude_m',
    'height_dbh_ratio', 'crown_trunk_ratio', 'canopy_volume_proxy', 'trunk_slenderness',
    'altitude_normalized', 'altitude_height_interaction', 'altitude_crown_interaction',
    'total_parts_used',
    'Geographic_Zone_encoded', 'Tree_Growth_Habitat_encoded', 'Topography_encoded',
    'Soil_Texture_encoded', 'Farm_Cultivated_encoded',
    'taste_attribute', 'medicine_use', 'stem_used', 'plant_use_count',
    'parts_used_count', 'total_special_attributes',
]

CATEGORICAL_COLS = [
    'Geographic_Zone', 'Tree_Growth_Habitat', 'Topography',
    'Soil_Texture', 'Farm_Cultivated',
]

NUMERIC_DEFAULTS = {
    'total_parts_used': 3.0,
    'taste_attribute': 0.0,
    'medicine_use': 0.0,
    'stem_used': 0.0,
    'plant_use_count': 2.0,
    'parts_used_count': 2.0,
    'total_special_attributes': 0.0,
}

EPS = 0.1

def engineer_dataframe(df, altitude_min=None, altitude_max=None):
    df = df.copy()
    if altitude_min is None:
        altitude_min = float(df['Altitude_m'].min())
    if altitude_max is None:
        altitude_max = float(df['Altitude_m'].max())

    df['height_dbh_ratio'] = df['Height_m'] / (df['Trunk_Diameter_m'] + EPS)
    df['crown_trunk_ratio'] = df['Crown_Diameter_m'] / (df['Trunk_Diameter_m'] + EPS)
    df['canopy_volume_proxy'] = df['Height_m'] * df['Crown_Diameter_m'] ** 2
    df['trunk_slenderness'] = df['Height_m'] / (df['Trunk_Diameter_m'] + EPS)
    df['altitude_normalized'] = (df['Altitude_m'] - altitude_min) / (altitude_max - altitude_min + EPS)
    df['altitude_height_interaction'] = df['Altitude_m'] * df['Height_m']
    df['altitude_crown_interaction'] = df['Altitude_m'] * df['Crown_Diameter_m']

    if 'total_parts_used' not in df.columns:
        parts = ['Uses_Fruit', 'Uses_Leaf', 'Uses_Stem', 'Uses_Root', 'Uses_Seed']
        if all(p in df.columns for p in parts):
            df['total_parts_used'] = df[parts].sum(axis=1)
        else:
            df['total_parts_used'] = NUMERIC_DEFAULTS['total_parts_used']

    for col, default in NUMERIC_DEFAULTS.items():
        if col not in df.columns:
            df[col] = default
        else:
            df[col] = df[col].fillna(df[col].median() if df[col].notna().any() else default)
    return df, altitude_min, altitude_max

def encode_categoricals(df, label_encoders):
    df = df.copy()
    for col in CATEGORICAL_COLS:
        enc = label_encoders[col]
        known = set(enc.classes_)
        safe = df[col].astype(str).apply(lambda v: v if v in known else enc.classes_[0])
        df[col + '_encoded'] = enc.transform(safe)
    return df

def build_feature_row(raw, label_encoders, altitude_min, altitude_max):
    row = {
        'Height_m': float(raw['height_m']),
        'Crown_Diameter_m': float(raw['crown_diameter_m']),
        'Trunk_Diameter_m': float(raw['trunk_diameter_m']),
        'Altitude_m': float(raw['altitude_m']),
        'Geographic_Zone': str(raw['geographic_zone']),
        'Tree_Growth_Habitat': str(raw['tree_growth_habitat']),
        'Topography': str(raw['topography']),
        'Soil_Texture': str(raw['soil_texture']),
        'Farm_Cultivated': str(raw['farm_cultivated']),
    }
    for col, default in NUMERIC_DEFAULTS.items():
        row[col] = float(raw.get(col, default))

    df = pd.DataFrame([row])
    df, _, _ = engineer_dataframe(df, altitude_min, altitude_max)
    df = encode_categoricals(df, label_encoders)
    return df[FEATURES].to_numpy(dtype=float)
# -------------------------------------------

TARGETS = ['food', 'beverage', 'medicine', 'agronomic']

_CONFIDENCE = [
    (0.90, 'Very High'), (0.80, 'High'),
    (0.70, 'Moderate'), (0.60, 'Fair'), (0.0, 'Low'),
]


def _confidence(p):
    for thr, label in _CONFIDENCE:
        if p >= thr:
            return label
    return 'Low'


class Predictor:
    def __init__(self, model_dir):
        self.model_dir = model_dir
        self._lock = threading.RLock()
        self.reload()

    def reload(self):
        """(Re)load all artifacts from disk. Called after retraining."""
        with self._lock:
            md = self.model_dir
            with open(os.path.join(md, 'feature_list.json')) as f:
                self.features = json.load(f)['features']
            with open(os.path.join(md, 'feature_meta.json')) as f:
                meta = json.load(f)
                self.alt_min = meta['altitude_min']
                self.alt_max = meta['altitude_max']
            with open(os.path.join(md, 'label_encoders.pkl'), 'rb') as f:
                self.encoders = pickle.load(f)
            with open(os.path.join(md, 'scalers.pkl'), 'rb') as f:
                self.scalers = pickle.load(f)
            self.models, self.metadata = {}, {}
            for t in TARGETS:
                with open(os.path.join(md, f'baobab_{t}_best_model.pkl'), 'rb') as f:
                    self.models[t] = pickle.load(f)
                with open(os.path.join(md, f'baobab_{t}_metadata.json')) as f:
                    self.metadata[t] = json.load(f)

    def categories(self):
        """Valid selectable values for each categorical descriptor."""
        return {
            'geographic_zones': list(self.encoders['Geographic_Zone'].classes_),
            'tree_growth_habitats': list(self.encoders['Tree_Growth_Habitat'].classes_),
            'topographies': list(self.encoders['Topography'].classes_),
            'soil_textures': list(self.encoders['Soil_Texture'].classes_),
            'farm_cultivated_options': list(self.encoders['Farm_Cultivated'].classes_),
        }

    def predict(self, raw):
        with self._lock:
            X = build_feature_row(raw, self.encoders, self.alt_min, self.alt_max)
            out = {}
            for t in TARGETS:
                Xs = self.scalers[t].transform(X)
                model = self.models[t]
                pred = model.predict(Xs)[0]
                proba = model.predict_proba(Xs)[0]
                conf = float(np.max(proba))
                out[t] = {
                    'prediction': int(pred),
                    'suitable': bool(pred) if t != 'agronomic' else None,
                    'probability': conf,
                    'confidence_level': _confidence(conf),
                    'class_probabilities': [float(p) for p in proba],
                    'model_accuracy': float(self.metadata[t]['best_accuracy']),
                    'algorithm': self.metadata[t]['best_model'],
                }
            return {'predictions': out, 'recommendations': self._recommend(out)}

    @staticmethod
    def _recommend(pred):
        recs = []
        if pred['food']['suitable']:
            recs.append('Food potential: strong characteristics for food use — leaves or '
                        'fruit pulp are viable for consumption or sale.')
        else:
            recs.append('Food potential: weak alignment with food-yielding trees; focus on other uses.')
        if pred['beverage']['suitable']:
            recs.append('Beverage potential: fruit pulp is suitable for juice extraction or brewing.')
        if pred['medicine']['suitable']:
            recs.append('Medicinal potential: bark, roots or leaves show properties suited to '
                        'traditional remedies.')
        agro = pred['agronomic']['prediction']
        if agro == 2:
            recs.append('Agronomic value (HIGH): excellent vitality — recommended for commercial '
                        'farming or conservation.')
        elif agro == 1:
            recs.append('Agronomic value (MEDIUM): moderate potential — suited to local or '
                        'small-scale mixed farming.')
        else:
            recs.append('Agronomic value (LOW): limited vitality — may struggle in intensive farming.')
        return recs
