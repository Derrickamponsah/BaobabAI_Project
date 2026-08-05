# Baobab Tree Analysis — Mobile Application

A full-stack system that predicts a baobab tree's **food**, **beverage**,
**medicinal** suitability and its **agronomic value** from field
measurements or from a **photograph**. It replaces the earlier web
application with a **Flutter mobile app** backed by a **Flask REST API**,
a **database**, user **sign-up/login**, and **automatic model retraining**
from data collected in the field.

```
baobab_mobile_app/
├── backend/     Python + Flask API, ML models, database, auto-retraining
├── mobile/      Flutter mobile application (Android / iOS)
└── docs/        API reference and architecture notes
```

## Key features

| Requirement | Where it lives |
|---|---|
| Mobile application | `mobile/` (Flutter) |
| Sign-up / login | `backend/auth/routes.py`, `mobile/lib/screens/{signup,login}_screen.dart` |
| Manual feature input | `mobile/lib/screens/manual_input_screen.dart` |
| Image upload → deduce tree dimensions | `backend/ml/image_features.py`, `mobile/lib/screens/image_input_screen.dart` |
| Selectable soil / location / site options | `/api/categories` + dropdowns in the manual screen |
| Database | `backend/database/models.py` (SQLite via SQLAlchemy) |
| Automatic retraining from the database | `backend/ml/trainer.py`, `backend/ml/auto_retrain.py` |

---

## 1. Backend setup (Python 3.10+)

```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# One-time: train the initial models from the bundled dataset.
python scripts/train_initial.py

# Start the API (http://0.0.0.0:5000)
python app.py
```

The pre-trained model artifacts are already included in `backend/models/`,
so you can skip `train_initial.py` and run `python app.py` directly.

Quick check:

```bash
curl http://localhost:5000/api/health
```

## 2. Mobile setup (Flutter 3.x)

```bash
cd mobile
flutter create .          # generates android/ and ios/ platform folders
flutter pub get
```

Set the API address in `mobile/lib/config.dart`:

* Android emulator → `http://10.0.2.2:5000`
* iOS simulator → `http://127.0.0.1:5000`
* Physical device → `http://<your-computer-LAN-IP>:5000`

Add permissions (see `docs/ANDROID_PERMISSIONS.md`) then run:

```bash
flutter run
```

## 3. Using the app

1. **Sign up** for an account (the first account becomes the admin).
2. Choose **Manual entry** or **Analyse from photo**.
   * *Photo*: pick/take a baobab image; the backend estimates height,
     crown and trunk size. You confirm/adjust the values, then select the
     site descriptors (soil, zone, topography, …) that a photo cannot give.
3. View the **predictions**, confidence levels and recommendations.
4. Tap **Confirm / correct** to submit the true attributes. These are
   stored in the database and, once enough accumulate, the models
   **retrain automatically** — the app keeps improving with use.

See `docs/API.md` for the full endpoint reference and
`docs/ARCHITECTURE.md` for the system design.

## Note on image-based estimation

Deriving absolute tree dimensions from a single uncalibrated photo is
inherently approximate. The app therefore treats image estimates as
**editable suggestions** that the user confirms before prediction, and it
supports an optional **scale reference** (an object of known height in the
frame) for accurate sizing. This is documented honestly rather than
over-claimed.
