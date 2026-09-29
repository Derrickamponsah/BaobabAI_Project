from ml.predictor import Predictor
import os
import json

# init predictor
p = Predictor(os.path.join(os.path.dirname(__file__), 'models'))

# mock input
raw = {
    'height_m': 10,
    'crown_diameter_m': 5,
    'trunk_diameter_m': 1.5,
    'altitude_m': 500,
    'geographic_zone': 'Savannah',
    'tree_growth_habitat': 'Wild',
    'topography': 'Flat',
    'soil_texture': 'Sandy',
    'farm_cultivated': 'No'
}

res = p.predict(raw)
print(json.dumps(res, indent=2))
