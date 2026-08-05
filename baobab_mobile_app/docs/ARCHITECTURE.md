# System Architecture

## Overview

```
┌──────────────────────────┐        HTTPS / JSON        ┌───────────────────────────────┐
│      Flutter Mobile App  │  ───────────────────────▶  │          Flask REST API        │
│                          │                            │                               │
│  Sign up / Login         │  ◀───────────────────────  │  /api/auth  (JWT)             │
│  Manual input            │                            │  /api/categories              │
│  Image upload            │                            │  /api/predict                 │
│  Results + Recommend.    │                            │  /api/predict/image (OpenCV)  │
│  Confirm / correct       │                            │  /api/feedback                │
│  History                 │                            │  /api/retrain, /models/status │
└──────────────────────────┘                            └───────────────┬───────────────┘
                                                                         │
                          ┌──────────────────────────────────────────────┼───────────────┐
                          │                                              │               │
                   ┌──────▼───────┐                        ┌─────────────▼──┐   ┌────────▼─────────┐
                   │  Predictor   │                        │  SQLite DB      │   │  Auto-retrainer  │
                   │  4 models    │                        │  users          │   │  threshold +     │
                   │  scaler+enc. │◀── hot reload ────────│  predictions    │──▶│  scheduler       │
                   └──────────────┘                        │  training_samples│   │  (trainer.py)    │
                                                           │  model_versions │   └──────────────────┘
                                                           └─────────────────┘
```

## Components

### Mobile app (Flutter)
A single Dart codebase (`mobile/lib`) organised into `screens/`,
`services/` (auth + API HTTP clients), `models/` (JSON models),
`widgets/` and `theme/`. Session tokens are persisted with
`shared_preferences`; images are captured with `image_picker`.

### Backend (Flask)
An application-factory Flask app (`backend/app.py`) that composes four
blueprints: **auth**, **predict**, **feedback** and **retrain**. JWT
protects every data endpoint.

### Machine-learning layer
`ml/feature_engineering.py` is the single source of truth for the
23-feature representation, guaranteeing that training, retraining and live
prediction always build features identically. `ml/predictor.py` loads the
four best models (food, beverage, medicine, agronomic) with their scalers
and label encoders and supports hot-reloading after a retrain.

### Image feature extraction
`ml/image_features.py` segments the tree with OpenCV (HSV canopy mask +
Otsu trunk mask), measures the silhouette in pixels, and converts to
metres via a scale reference (or a documented assumption). Results are
returned as editable estimates.

### Database (SQLAlchemy + SQLite)
Four tables: `users`, `prediction_records`, `training_samples`,
`model_versions`. `training_samples` is the engine of continuous
improvement — every expert-confirmed observation is stored here.

### Automatic retraining
`ml/auto_retrain.py` runs retraining off the request thread. Two triggers:

1. **Threshold** — after new confirmed samples reach `RETRAIN_THRESHOLD`
   (default 20), a background retrain launches.
2. **Scheduled** — an APScheduler job re-checks every
   `RETRAIN_INTERVAL_HOURS` (default 24 h).

`ml/trainer.py` merges the original base dataset with all confirmed
`training_samples`, rebuilds features, balances classes by oversampling,
retrains the five candidate algorithms per target, selects the best by
test accuracy, versions it in `model_versions`, persists it, marks the
samples as used, and hot-reloads the live predictor.

## Prediction data flow

1. Client collects features (manual, or image-estimated + confirmed).
2. `POST /api/predict` → `Predictor.predict()` builds the 23-vector,
   scales per-target, runs each model, returns predictions + confidence +
   recommendations, and records the prediction in the database.
3. User confirms/corrects → `POST /api/feedback` writes a
   `TrainingSample` and checks the retrain trigger.

## Consistency guarantee
Because training, retraining and inference all call the **same**
`feature_engineering` functions with the **same** persisted altitude
bounds and label encoders, a feature vector produced at prediction time is
identical in construction to the ones the models were trained on.
