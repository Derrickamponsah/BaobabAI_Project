# Baobab Tree Analysis — Deployment Guide

Step-by-step instructions for:

1. **Hosting the Flask backend and PostgreSQL database on [Render](https://render.com)**
2. **Installing the mobile app on your phone** (without Play Store / App Store)

---

## Part A — Deploy the Backend to Render

### Prerequisites

| What you need | Why |
|---|---|
| A free [Render account](https://dashboard.render.com/register) | Hosts the API and database |
| A [GitHub](https://github.com) account | Render deploys from a Git repo |
| Git installed on your computer | To push your code |

---

### Step 1 — Push your project to GitHub

> [!NOTE]
> If your project is already on GitHub, skip to Step 2.

1. Go to [github.com/new](https://github.com/new) and create a **new repository** (e.g. `baobab-mobile-app`). Keep it **Private** if you prefer.

2. In your terminal, navigate to the **root** of the project and run:

```bash
cd C:\Users\frida\Downloads\baobab_mobile_app\baobab_mobile_app

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<YOUR_USERNAME>/baobab-mobile-app.git
git push -u origin main
```

> [!TIP]
> Make sure the `backend/venv/` folder is listed in your `.gitignore` so you don't push the virtual environment.

---

### Step 2 — Create a PostgreSQL database on Render

1. Log in to **[Render Dashboard](https://dashboard.render.com)**.
2. Click **New +** → **PostgreSQL**.
3. Fill in:
   - **Name**: `baobab-db`
   - **Database**: `baobab`
   - **User**: `baobab_user` (or leave the default)
   - **Region**: Choose the one closest to your users
   - **Plan**: **Free** (good enough for testing)
4. Click **Create Database**.
5. Once it's created, go to the database page and find the **Internal Database URL** — it looks like:

```
postgresql://baobab_user:XXXXXXXXXX@dpg-xxxxx/baobab
```

6. Also copy the **External Database URL** (you'll need this if you ever want to connect from your local machine).

> [!IMPORTANT]
> Keep the **Internal Database URL** handy — you will paste it into the backend service in the next step.

---

### Step 3 — Create the backend Web Service on Render

1. In the Render Dashboard, click **New +** → **Web Service**.
2. Connect your **GitHub account** if you haven't already, and select your `baobab-mobile-app` repository.
3. Fill in the settings:

| Setting | Value |
|---|---|
| **Name** | `baobab-api` |
| **Region** | Same region as your database |
| **Root Directory** | `backend` |
| **Runtime** | `Python` |
| **Build Command** | `pip install -r requirements.txt` |
| **Start Command** | `gunicorn app:app --bind 0.0.0.0:10000 --timeout 120` |
| **Plan** | Free |

4. Scroll down to **Environment Variables** and add:

| Key | Value |
|---|---|
| `BAOBAB_DATABASE_URL` | *(Paste the **Internal Database URL** from Step 2)* |
| `BAOBAB_SECRET_KEY` | *(A long random string, e.g. run `python -c "import secrets; print(secrets.token_hex(32))"`)* |
| `PYTHON_VERSION` | `3.11.9` |

> [!WARNING]
> Render's free PostgreSQL uses the prefix `postgres://` but SQLAlchemy requires `postgresql://`. If your Internal URL starts with `postgres://`, change it to `postgresql://` when pasting.

5. Click **Create Web Service**.

Render will now:
- Install your Python dependencies
- Start the Flask app via Gunicorn

Wait for the deploy to show **"Live"**. Your API will be available at:

```
https://baobab-api.onrender.com
```

*(The exact URL is shown on the service's dashboard page.)*

---

### Step 4 — Verify the deployment

Open a browser or run:

```bash
curl https://baobab-api.onrender.com/api/health
```

You should see:

```json
{"status": "healthy", "models_loaded": 4, "features": 20}
```

If you see an error, check the **Logs** tab on your Render service page for details.

> [!NOTE]
> Render's free tier spins down after 15 minutes of inactivity. The **first request after idle** may take 30–60 seconds while the service restarts. This is normal for the free plan.

---

### Step 5 — (Optional) Seed the database

The models are pre-trained and bundled in `backend/models/`, so predictions work immediately. The database tables (`users`, `prediction_records`, `training_samples`, `model_versions`) are created automatically on first startup by SQLAlchemy's `db.create_all()`.

---

## Part B — Install the Mobile App on Your Phone

You have two paths depending on your phone:

- **Android** → Build an APK and sideload it (easiest)
- **iOS** → Use Xcode to install onto a physical iPhone (requires a Mac)

---

### Option 1 — Android (Recommended for testing)

#### Prerequisites

| What you need | Why |
|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) installed | To build the APK |
| [Android SDK / Android Studio](https://developer.android.com/studio) installed | Provides build tools |
| A USB cable | To connect your phone |

#### Step 1 — Update the API URL

Open `mobile/lib/config.dart` and set the URL to your **Render backend**:

```dart
class AppConfig {
  static const String apiBaseUrl = 'https://baobab-api.onrender.com';  // ← your Render URL
  static const String apiPrefix = '$apiBaseUrl/api';
}
```

#### Step 2 — Allow internet access (AndroidManifest.xml)

Open `mobile/android/app/src/main/AndroidManifest.xml` and make sure the `<manifest>` tag contains the internet permission, and the `<application>` tag has `android:usesCleartextTraffic="true"`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- ADD THIS LINE if not already present -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="baobab_app"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        <!-- ... rest stays the same ... -->
    </application>
    <!-- ... -->
</manifest>
```

#### Step 3 — Enable Developer Mode on your phone

1. Go to **Settings → About Phone**.
2. Tap **Build Number** 7 times until you see *"You are now a developer!"*.
3. Go back to **Settings → Developer Options**.
4. Enable **USB Debugging**.

#### Step 4 — Connect your phone and verify

Plug your phone into your computer via USB. Accept the *"Allow USB Debugging"* prompt on your phone, then run:

```bash
cd mobile
flutter devices
```

You should see your phone listed, for example:

```
Samsung Galaxy A54 (mobile) • RXXXXXXXXX • android-arm64 • Android 14
```

#### Step 5 — Build and install the APK

**Option A — Direct install (fastest for testing):**

```bash
flutter run --release
```

This builds a release APK and installs it directly onto your connected phone. The app will launch automatically.

**Option B — Build APK file to share / install manually:**

```bash
flutter build apk --release
```

The APK will be at:

```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

Transfer this file to your phone (via USB, email, Google Drive, WhatsApp, etc.) and tap it to install.

> [!NOTE]
> Your phone may warn about "installing from unknown sources". Go to **Settings → Security** (or **Settings → Apps → Special Access → Install Unknown Apps**) and allow your file manager or browser to install apps.

#### Step 6 — Verify

Open the app on your phone. You should see the login / sign-up screen. Create an account and make a prediction to confirm the app is talking to your Render backend.

---

### Option 2 — iOS (Requires a Mac)

#### Prerequisites

| What you need | Why |
|---|---|
| A Mac with [Xcode](https://developer.apple.com/xcode/) installed | Only way to build for iOS |
| An [Apple ID](https://appleid.apple.com) (free) | To sign the app |
| Flutter SDK installed on the Mac | To build the app |
| A USB cable (Lightning or USB-C) | To connect your iPhone |

#### Step 1 — Update the API URL

Same as Android Step 1 — edit `mobile/lib/config.dart` to point to your Render URL.

#### Step 2 — Open the iOS project in Xcode

```bash
cd mobile
flutter pub get
open ios/Runner.xcworkspace
```

#### Step 3 — Configure signing

1. In Xcode, select the **Runner** project in the left sidebar.
2. Go to the **Signing & Capabilities** tab.
3. Check **"Automatically manage signing"**.
4. Set **Team** to your Apple ID (Personal Team).
5. Change the **Bundle Identifier** to something unique, e.g.:
   ```
   com.yourname.baobabapp
   ```

#### Step 4 — Connect your iPhone

1. Plug your iPhone into the Mac.
2. On the iPhone, go to **Settings → Privacy & Security → Developer Mode** and enable it (iOS 16+).
3. Trust the computer when prompted.

#### Step 5 — Build and install

```bash
flutter run --release
```

Or press the **▶ Run** button in Xcode with your iPhone selected as the target device.

#### Step 6 — Trust the developer profile

The first time you run a sideloaded app on iOS:

1. Go to **Settings → General → VPN & Device Management** (or **Profiles & Device Management**).
2. Find your Apple ID under *"Developer App"*.
3. Tap **Trust "[your Apple ID]"** → **Trust**.

Now open the app — it should launch normally.

> [!CAUTION]
> Free Apple IDs require you to **re-sign the app every 7 days**. After 7 days, the app will stop opening and you must reconnect to Xcode and run again. A paid Apple Developer account ($99/year) extends this to 1 year.

---

## Part C — Connect Your Local PostgreSQL Client to the Render Database

This lets you browse tables, run queries, and monitor all database activity from your own computer using tools like **psql**, **pgAdmin**, or **DBeaver**.

---

### Pros and Cons

| | Pros ✅ | Cons ❌ |
|---|---|---|
| **Visibility** | See all tables, rows, and data in real time — users, predictions, training samples, model versions | Exposes your production database to external connections (security risk if credentials leak) |
| **Debugging** | Run ad-hoc SQL queries to diagnose issues (e.g. "why did this prediction fail?") | Accidental `UPDATE` / `DELETE` queries can corrupt or destroy production data |
| **Data export** | Easily export data to CSV/Excel for reports or analysis | External connections add latency (~100–300ms per query vs. near-instant internally) |
| **Familiar tools** | Use powerful GUI tools (pgAdmin, DBeaver) instead of the limited Render dashboard | Free Render databases have limited connections (usually max 10) — a local client uses one of those slots |
| **No code changes** | Works with your existing database, no app modifications needed | The External Database URL on Render's free plan **expires when the database expires** (90 days on the free tier) |

> [!TIP]
> **Recommendation**: Connect locally for development and debugging. For production monitoring, consider using the Render dashboard's built-in logs and metrics instead.

---

### Step 1 — Get your External Database URL from Render

1. Go to the [Render Dashboard](https://dashboard.render.com).
2. Click on your **baobab-db** PostgreSQL instance.
3. Scroll to the **Connections** section.
4. Copy the **External Database URL**. It looks like:

```
postgresql://baobab_user:XXXXXXXXXX@dpg-xxxxx.oregon-postgres.render.com:5432/baobab
```

You will also see the individual connection details:

| Field | Example value |
|---|---|
| **Hostname** | `dpg-xxxxx.oregon-postgres.render.com` |
| **Port** | `5432` |
| **Database** | `baobab` |
| **Username** | `baobab_user` |
| **Password** | `XXXXXXXXXX` |

> [!IMPORTANT]
> The **External URL** is different from the Internal URL. The Internal URL only works between Render services. You need the **External** one to connect from your computer.

---

### Step 2 — Install a PostgreSQL client

Choose **one** of the following:

#### Option A — psql (command-line)

psql comes bundled with PostgreSQL. If you don't have it:

1. Download PostgreSQL from [postgresql.org/download/windows](https://www.postgresql.org/download/windows/).
2. During installation, make sure **"Command Line Tools"** is checked.
3. After install, open a new terminal and verify:

```bash
psql --version
```

#### Option B — pgAdmin (GUI — recommended for beginners)

1. Download from [pgadmin.org/download](https://www.pgadmin.org/download/).
2. Install and launch.

#### Option C — DBeaver (GUI — more advanced)

1. Download from [dbeaver.io/download](https://dbeaver.io/download/).
2. Install and launch.

---

### Step 3 — Connect to the Render database

#### Using psql (command-line)

Paste the External Database URL directly:

```bash
psql "postgresql://baobab_user:XXXXXXXXXX@dpg-xxxxx.oregon-postgres.render.com:5432/baobab"
```

Once connected, try:

```sql
-- List all tables
\dt

-- See all registered users
SELECT id, full_name, email, role, created_at FROM users;

-- See recent predictions
SELECT id, user_id, source, created_at FROM prediction_records ORDER BY created_at DESC LIMIT 10;

-- See training samples waiting to be used
SELECT id, target_food, target_beverage, target_medicine, target_agronomic, used_for_training
FROM training_samples ORDER BY created_at DESC LIMIT 10;

-- See model versions and accuracy
SELECT target, version, algorithm, accuracy, is_current, created_at FROM model_versions ORDER BY created_at DESC;
```

Type `\q` to exit.

#### Using pgAdmin (GUI)

1. Open pgAdmin.
2. Right-click **Servers** → **Register** → **Server…**
3. **General** tab:
   - **Name**: `Baobab Render DB`
4. **Connection** tab:
   - **Host**: `dpg-xxxxx.oregon-postgres.render.com` *(from Render)*
   - **Port**: `5432`
   - **Maintenance database**: `baobab`
   - **Username**: `baobab_user`
   - **Password**: *(paste from Render)*
   - Check **Save password**
5. **SSL** tab:
   - **SSL mode**: `Require`
6. Click **Save**.

You can now expand the tree: **Baobab Render DB → Databases → baobab → Schemas → public → Tables** to see all four tables (`users`, `prediction_records`, `training_samples`, `model_versions`).

Right-click any table → **View/Edit Data → All Rows** to browse.

#### Using DBeaver (GUI)

1. Open DBeaver.
2. Click **New Database Connection** (plug icon) → select **PostgreSQL** → **Next**.
3. Fill in:
   - **Host**: `dpg-xxxxx.oregon-postgres.render.com`
   - **Port**: `5432`
   - **Database**: `baobab`
   - **Username**: `baobab_user`
   - **Password**: *(paste from Render)*
4. Click the **SSL** tab → check **Use SSL** → set SSL mode to **require**.
5. Click **Test Connection** — it should say "Connected".
6. Click **Finish**.

Navigate: **baobab → public → Tables** to see and browse all your tables.

---

### Step 4 — Useful queries for monitoring

Here are some queries you can run to monitor your app's activity:

```sql
-- 📊 Total users signed up
SELECT COUNT(*) AS total_users FROM users;

-- 📊 Predictions per day
SELECT DATE(created_at) AS day, COUNT(*) AS predictions
FROM prediction_records
GROUP BY DATE(created_at)
ORDER BY day DESC;

-- 📊 Predictions by source (manual vs image)
SELECT source, COUNT(*) AS count
FROM prediction_records
GROUP BY source;

-- 📊 Training samples ready for next retrain
SELECT COUNT(*) AS pending_samples
FROM training_samples
WHERE used_for_training = FALSE;

-- 📊 Current best model per target
SELECT target, algorithm, accuracy, version, created_at
FROM model_versions
WHERE is_current = TRUE
ORDER BY target;
```

> [!WARNING]
> **Be careful with write operations** (`INSERT`, `UPDATE`, `DELETE`, `DROP`). You are connected to your **live production database**. If you accidentally delete data, there is no undo. Consider using `BEGIN` / `ROLLBACK` for safety:
> ```sql
> BEGIN;
> DELETE FROM training_samples WHERE id = 99;
> -- Check the result, then either:
> ROLLBACK;  -- undo
> -- or:
> COMMIT;    -- confirm
> ```

---

## Quick Reference — Full Command Sequence

### Deploy backend (one-time)

```bash
# 1. Push code to GitHub
cd C:\Users\frida\Downloads\baobab_mobile_app\baobab_mobile_app
git init && git add . && git commit -m "Initial commit"
git remote add origin https://github.com/<YOU>/baobab-mobile-app.git
git push -u origin main

# 2. Create PostgreSQL + Web Service on Render Dashboard (see Steps 2–3 above)

# 3. Verify
curl https://baobab-api.onrender.com/api/health
```

### Install on Android phone (one-time)

```bash
# 1. Update API URL in mobile/lib/config.dart

# 2. Connect phone via USB with USB Debugging enabled

# 3. Build and install
cd mobile
flutter pub get
flutter run --release
```

---

## Troubleshooting

| Problem | Solution |
|---|---|
| Render deploy fails with `ModuleNotFoundError` | Check that **Root Directory** is set to `backend` in Render settings |
| `postgres://` vs `postgresql://` error | Change the prefix in your `BAOBAB_DATABASE_URL` env var to `postgresql://` |
| App can't reach the API | Make sure `config.dart` has your Render URL (not `127.0.0.1`) and the phone has internet |
| `flutter run` says "no devices" | Enable USB Debugging, try a different cable, run `flutter doctor` |
| APK install blocked | Enable "Install from Unknown Sources" for your file manager in Android Settings |
| iOS app stops working after 7 days | Re-run `flutter run` from Xcode — free signing profiles expire weekly |
| Render free tier is slow on first request | Normal — the service spins down after 15 min of inactivity. First request takes ~30–60s to wake up |
| Image upload fails | Check that `MAX_CONTENT_LENGTH` (10 MB) is enough and that the `INTERNET` permission is in `AndroidManifest.xml` |
