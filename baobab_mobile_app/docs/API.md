# API Reference

Base URL: `http://<host>:5000/api`
All endpoints except sign-up, login and `/categories` require a JWT:
`Authorization: Bearer <token>`.

---

## Auth

### POST `/auth/signup`
```json
{ "full_name": "Jane Doe", "email": "jane@x.org", "password": "secret123" }
```
→ `201` `{ "token": "...", "user": { ... } }`
The **first** account created becomes an `admin`.

### POST `/auth/login`
```json
{ "email": "jane@x.org", "password": "secret123" }
```
→ `200` `{ "token": "...", "user": { ... } }`

### GET `/auth/me`
→ `200` `{ "user": { ... } }`

---

## Prediction

### GET `/categories`
Selectable dropdown values.
```json
{
  "geographic_zones": ["Middle_Zone", "Northern_Zone", "Southern_Zone"],
  "tree_growth_habitats": ["Drooping", "Erect", "Spreading"],
  "topographies": ["Flat land", "Hilly", "..."],
  "soil_textures": ["Clay", "Loam", "Sandy loam", "..."],
  "farm_cultivated_options": ["Field", "Orchard", "Parkland", "..."]
}
```

### POST `/predict`
```json
{
  "height_m": 12.5, "crown_diameter_m": 9.0, "trunk_diameter_m": 1.4,
  "altitude_m": 220, "geographic_zone": "Northern_Zone",
  "tree_growth_habitat": "Spreading", "topography": "Flat land",
  "soil_texture": "Sandy loam", "farm_cultivated": "Parkland",
  "source": "manual"
}
```
→ `200`
```json
{
  "predictions": {
    "food":      { "prediction": 1, "suitable": true,  "probability": 0.94,
                   "confidence_level": "Very High", "class_probabilities": [0.06,0.94],
                   "model_accuracy": 0.91, "algorithm": "svm" },
    "beverage":  { "...": "..." },
    "medicine":  { "...": "..." },
    "agronomic": { "prediction": 2, "suitable": null, "probability": 0.95,
                   "confidence_level": "Very High", "class_probabilities": [0.02,0.03,0.95],
                   "model_accuracy": 0.95, "algorithm": "svm" }
  },
  "recommendations": ["Food potential: ...", "Agronomic value (HIGH): ..."],
  "record_id": 12
}
```

### POST `/predict/image`  (multipart/form-data)
Fields: `image` (file, required), `ref_object_height_m` (optional),
`ref_object_pixel_height` (optional).
→ `200`
```json
{
  "success": true,
  "estimated_features": {
    "height_m": 10.0, "crown_diameter_m": 6.9,
    "trunk_diameter_m": 0.81, "dbh_mm": 814.0
  },
  "confidence": "low",
  "scale_source": "assumed_tree_height",
  "notes": ["No scale reference supplied; absolute sizes are approximate ..."],
  "message": "Estimated morphology from image. Please confirm or adjust ..."
}
```

### GET `/history`
→ `200` `{ "history": [ { "id", "source", "input", "result", "created_at" }, ... ] }`

---

## Feedback & retraining

### POST `/feedback`
Stores an expert-confirmed observation as a training sample and checks the
auto-retrain trigger.
```json
{
  "features": { "height_m": 12.5, "crown_diameter_m": 9.0, "...": "..." },
  "labels": { "food": 1, "beverage": 0, "medicine": 1, "agronomic": 2 }
}
```
→ `201` `{ "sample_id": 5, "retrain": { "triggered": false, "pending": 5, "threshold": 20 } }`

### POST `/retrain`  *(admin only)*
Forces an immediate background retrain.
→ `202` `{ "status": { "triggered": true, "pending": 5 } }`

### GET `/models/status`
→ `200`
```json
{
  "models": { "food": { "algorithm": "svm", "accuracy": 0.91 }, "...": "..." },
  "pending_samples": 5, "retrain_threshold": 20
}
```

### GET `/models/versions`
→ `200` `{ "versions": [ { "target", "version", "algorithm", "accuracy", "is_current", "created_at" }, ... ] }`

---

## Health

### GET `/health`
→ `200` `{ "status": "healthy", "models_loaded": 4, "features": 23 }`
