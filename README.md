# FloodSense 🌊

> **A real-time flood risk monitoring system for Malaysian river catchments.**  
> Built with FastAPI (Python) on the backend and React Native (Expo) on the mobile frontend.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Repository Structure](#repository-structure)
4. [Backend Setup](#backend-setup)
5. [Frontend Setup](#frontend-setup)
6. [API Endpoint Reference](#api-endpoint-reference)
7. [Configuration & Environment Variables](#configuration--environment-variables)
8. [Pointing the App at a Real Device](#pointing-the-app-at-a-real-device)
9. [Next Steps — Integrating a Real LSTM Model](#next-steps--integrating-a-real-lstm-model)

---

## Project Overview

FloodSense aggregates water-level and rainfall sensor data from five major Malaysian river stations, runs a risk-scoring model, and delivers colour-coded risk alerts to a mobile app in real time.

**Key features:**
- **Live station readings** — water level (m), rainfall (mm³), risk label (Safe / Warning / Danger)
- **Flood risk prediction** — placeholder LSTM formula (ready to swap for a real model)
- **Push notifications** — Expo Push API; triggered when a user's device enters a Danger zone
- **User profiles** — station preferences, alert areas, background location tracking
- **Accessible UI** — soft-blue palette, large fonts (≥ 16 sp body), high-contrast badges

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Mobile App (Expo)                        │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────────────┐  │
│  │HomeScreen│  │MapScreen │  │      ProfileScreen           │  │
│  └────┬─────┘  └────┬─────┘  └──────────────┬───────────────┘  │
│       │             │                        │                  │
│  ┌────▼─────────────▼────────────────────────▼───────────────┐  │
│  │          React Navigation (Bottom Tabs)                   │  │
│  └───────────────────────┬───────────────────────────────────┘  │
│                          │                                      │
│  ┌───────────────────────▼───────────────────────────────────┐  │
│  │  Services / Hooks                                         │  │
│  │  apiService (axios) │ locationService │ notificationSvc   │  │
│  │  useFloodData hook  │ useUserProfile hook                 │  │
│  └───────────────────────┬───────────────────────────────────┘  │
└──────────────────────────┼──────────────────────────────────────┘
                           │  HTTP/REST  (JSON)
                           │
┌──────────────────────────▼──────────────────────────────────────┐
│                   FastAPI Backend (port 8000)                   │
│                                                                 │
│  GET /health                                                    │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  ┌─────────────┐  │
│  │  /users  │  │/stations │  │/predictions│  │/notifications│  │
│  └────┬─────┘  └────┬─────┘  └─────┬──────┘  └──────┬──────┘  │
│       │             │               │                 │         │
│  ┌────▼─────────────▼───────────────▼─────────────────▼──────┐  │
│  │          Pydantic Models  (models.py)                      │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                 │
│  In-memory store (dict)          Expo Push API (httpx)         │
└─────────────────────────────────────────────────────────────────┘

Legend:
  Mobile ──HTTP──▶ Backend ──HTTP──▶ Expo Push Servers ──▶ Device
```

**Data flow:**
1. App launches → `useFloodData` polls `/stations/` every 60 s.
2. User selects a station → app fetches `/stations/{id}/history`.
3. Background location task fires every 30 s → posts to `/users/{id}/location`.
4. Backend `/notifications/trigger` scans all users whose location falls inside a Danger `AlertArea` (haversine check) and pushes via Expo.

---

## Repository Structure

```
FloodSense/
├── README.md                        ← this file
│
├── backend/                         ← FastAPI Python backend
│   ├── main.py                      # App entrypoint + CORS + router registration
│   ├── models.py                    # Pydantic v2 data models
│   ├── requirements.txt             # Python dependencies
│   ├── README.md                    # Backend-specific docs
│   └── routers/
│       ├── __init__.py
│       ├── users.py                 # User CRUD + location update
│       ├── stations.py              # Station readings & 24-h history
│       ├── predictions.py           # Flood risk scoring (placeholder LSTM)
│       └── notifications.py         # Expo push notification dispatch
│
└── mobile/                          ← React Native / Expo frontend
    ├── App.tsx                      # Root component + navigation
    ├── app.json                     # Expo config
    ├── eas.json                     # EAS Build profiles
    ├── package.json                 # npm dependencies
    ├── babel.config.js
    ├── tsconfig.json
    ├── assets/                      # Icons & splash (replace placeholders)
    └── src/
        ├── constants/
        │   ├── api.ts               # API_BASE_URL + endpoint helpers
        │   └── theme.ts             # Colors, fonts, spacing
        ├── types/
        │   └── index.ts             # Shared TypeScript types
        ├── services/
        │   ├── apiService.ts        # Axios client
        │   ├── locationService.ts   # Expo Location + background task
        │   └── notificationService.ts
        ├── hooks/
        │   ├── useFloodData.ts      # Station data + 60-s polling
        │   └── useUserProfile.ts    # AsyncStorage-backed profile
        ├── screens/
        │   ├── HomeScreen.tsx
        │   ├── MapScreen.tsx
        │   └── ProfileScreen.tsx
        └── components/
            ├── RiskBadge.tsx
            └── StationCard.tsx
```

---

## Backend Setup

### Prerequisites
- Python **3.11+**
- `pip`

### 1 — Create and activate a virtual environment

```bash
# Windows (PowerShell)
cd c:\Dev\University\FloodSense\backend
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# macOS / Linux
cd /path/to/FloodSense/backend
python3 -m venv .venv
source .venv/bin/activate
```

### 2 — Install dependencies

```bash
pip install -r requirements.txt
```

**requirements.txt** pins:

| Package | Version |
|---------|---------|
| fastapi | ≥ 0.110.0 |
| uvicorn[standard] | ≥ 0.29.0 |
| pydantic | ≥ 2.0.0 |
| httpx | ≥ 0.27.0 |
| python-multipart | ≥ 0.0.9 |
| numpy | ≥ 1.26.0 |

### 3 — Run the development server

```bash
# Option A — via uvicorn directly (recommended, with live reload)
uvicorn main:app --host 0.0.0.0 --port 8000 --reload

# Option B — via python
python main.py
```

- **Local browser:** `http://localhost:8000`
- **Interactive Swagger UI:** `http://localhost:8000/docs`
- **ReDoc:** `http://localhost:8000/redoc`

> **Tip:** Use `--host 0.0.0.0` so that physical Android devices on the same Wi-Fi network can reach the server.

---

## Frontend Setup

### Prerequisites
- **Node.js** 18+ and **npm** 9+
- **Expo CLI** (`npm install -g expo-cli`) or use `npx expo`
- **EAS CLI** for APK builds (`npm install -g eas-cli`)
- **Expo Go** app on your phone (for Expo Go workflow) **or** Android Studio / Xcode for native builds

### 1 — Install dependencies

```bash
cd c:\Dev\University\FloodSense\mobile
npm install
```

### 2 — Start the Expo development server

```bash
npx expo start
```

Scan the QR code with **Expo Go** (Android/iOS) to launch the app instantly.

| Key | Action |
|-----|--------|
| `a` | Open on Android emulator |
| `i` | Open on iOS simulator |
| `w` | Open in web browser |

### 3 — Build an Android APK with EAS

```bash
# Log in to your Expo account first
eas login

# Build a shareable APK (preview profile)
eas build --platform android --profile preview
```

EAS Build profiles defined in `eas.json`:

| Profile | Type | Use |
|---------|------|-----|
| `development` | development client | Local development with custom native code |
| `preview` | APK (internal) | Shareable test APK without app-store submission |
| `production` | AAB | Google Play submission |

The finished APK download link appears in the EAS dashboard and in the terminal output.

---

## API Endpoint Reference

### Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Returns `{"status":"ok"}` |

### Users

| Method | Path | Description |
|--------|------|-------------|
| POST | `/users/` | Create a new user profile |
| GET | `/users/{user_id}` | Get user profile by ID |
| PUT | `/users/{user_id}` | Update user profile |
| POST | `/users/{user_id}/location` | Update last-known lat/lng |

**UserProfile schema:**
```json
{
  "id": "string",
  "name": "string",
  "email": "string",
  "home_address": "string",
  "selected_station_id": "string",
  "alert_areas": ["string"],
  "push_token": "string | null",
  "last_known_lat": "float | null",
  "last_known_lng": "float | null"
}
```

### Stations

| Method | Path | Description |
|--------|------|-------------|
| GET | `/stations/` | List all 5 mock stations |
| GET | `/stations/{station_id}` | Single station reading |
| GET | `/stations/{station_id}/history` | 24-hour water-level & rainfall arrays |

**Station IDs:** `SGK001` (Sg. Klang), `SGB001` (Sg. Gombak), `SGBatu001` (Sg. Batu), `SGL001` (Sg. Langat), `SGS001` (Sg. Selangor)

**Risk label thresholds:**

| Water Level | Risk Label |
|-------------|-----------|
| < 2.5 m | ✅ Safe |
| 2.5 – 4.0 m | ⚠️ Warning |
| > 4.0 m | 🔴 Danger |

### Predictions

| Method | Path | Description |
|--------|------|-------------|
| POST | `/predictions/predict` | Run risk scoring on provided history |
| GET | `/predictions/latest/{station_id}` | Mock latest prediction for a station |

**POST /predictions/predict body:**
```json
{
  "station_id": "SGK001",
  "water_level_history": [1.2, 1.5, 2.0, 2.3, 2.8, 3.1],
  "rainfall_history": [5.0, 10.0, 15.0, 20.0, 25.0, 30.0]
}
```

**Risk score formula (placeholder):**
```
risk_score = min(1.0, mean(last_6_water) / 5.0 + mean(last_6_rain) / 200.0)
```

| risk_score | Label |
|-----------|-------|
| < 0.4 | Safe |
| 0.4 – 0.7 | Warning |
| ≥ 0.7 | Danger |

### Notifications

| Method | Path | Description |
|--------|------|-------------|
| POST | `/notifications/trigger` | Scan users in Danger zones; push alerts via Expo |
| POST | `/notifications/send` | Push to a specific user by user_id |

**POST /notifications/send body:**
```json
{
  "user_id": "u001",
  "title": "Flood Warning",
  "body": "Water levels rising near your area.",
  "data": {"type": "flood_warning"}
}
```

Notifications are sent to `https://exp.host/--/api/v2/push/send` via **httpx**.

---

## Configuration & Environment Variables

The backend currently uses **no `.env` file** — all configuration is in-code for prototype purposes. When moving to production, extract these into environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Uvicorn bind address |
| `PORT` | `8000` | Uvicorn port |
| `EXPO_PUSH_URL` | `https://exp.host/--/api/v2/push/send` | Expo push endpoint |
| `CORS_ORIGINS` | `["*"]` | Allowed CORS origins (lock down for production) |

Recommended approach for production:

```bash
# Install python-dotenv
pip install python-dotenv

# Create backend/.env
HOST=0.0.0.0
PORT=8000
CORS_ORIGINS=https://yourfrontenddomain.com
```

Then load with `from dotenv import load_dotenv; load_dotenv()` in `main.py`.

---

## Pointing the App at a Real Device

The default `API_BASE_URL` in [`mobile/src/constants/api.ts`](mobile/src/constants/api.ts) is:

```typescript
export const API_BASE_URL = 'http://10.0.2.2:8000';
// 10.0.2.2 is the Android Emulator loopback alias for the host machine.
```

### Physical Android/iOS device over Wi-Fi

1. Find your development machine's local IP:
   ```powershell
   # Windows PowerShell
   Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object IPAddress
   ```
2. Edit `mobile/src/constants/api.ts`:
   ```typescript
   export const API_BASE_URL = 'http://192.168.1.XXX:8000'; // ← your machine's IP
   ```
3. Make sure the backend is running with `--host 0.0.0.0`:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```
4. Ensure your firewall allows inbound connections on port **8000**.
5. Both device and laptop must be on the **same Wi-Fi network**.

### Tunnel (no same-network requirement)

```bash
npx expo start --tunnel
```

Expo uses ngrok to expose the dev server publicly — the QR code URL will update automatically.

---

## Next Steps — Integrating a Real LSTM Model

The placeholder scoring formula in `backend/routers/predictions.py` is designed to be a **drop-in replacement target**.

### Step 1 — Train your LSTM

Suggested input features per time-step:
- `water_level_m` (normalised)
- `rainfall_mm3` (normalised)
- `hour_of_day` (cyclic sin/cos encoding)
- `day_of_week` (cyclic sin/cos encoding)

Suggested architecture:
```
Input → LSTM(64 units) → Dropout(0.2) → LSTM(32 units) → Dense(1, sigmoid)
```
Output: flood probability in `[0.0, 1.0]`.

Recommended libraries: **TensorFlow / Keras** or **PyTorch**.

### Step 2 — Export the model

```python
# Keras
model.save('floodsense_lstm.keras')

# PyTorch
torch.save(model.state_dict(), 'floodsense_lstm.pt')
```

Place the model file at `backend/model/floodsense_lstm.keras`.

### Step 3 — Add model-loading dependencies

```
# requirements.txt additions
tensorflow>=2.16.0
# or
torch>=2.3.0
```

### Step 4 — Replace the placeholder in `predictions.py`

```python
# At module load time (once)
import numpy as np
from tensorflow import keras

_model = keras.models.load_model('model/floodsense_lstm.keras')
_scaler_water = ...  # load your fitted MinMaxScaler
_scaler_rain  = ...

def _lstm_predict(water_history: list[float], rain_history: list[float]) -> float:
    seq = np.column_stack([
        _scaler_water.transform([[w] for w in water_history[-24:]]),
        _scaler_rain.transform([[r] for r in rain_history[-24:]]),
    ])
    X = seq[np.newaxis, ...]          # shape (1, 24, 2)
    return float(_model.predict(X, verbose=0)[0][0])
```

Replace the formula call in the `POST /predictions/predict` handler with `_lstm_predict(...)`.

### Step 5 — Automate periodic prediction

Add an `APScheduler` background job in `main.py` to call `/predictions/predict` for every station every 15 minutes and cache the result:

```bash
pip install apscheduler
```

```python
from apscheduler.schedulers.asyncio import AsyncIOScheduler

scheduler = AsyncIOScheduler()

@app.on_event("startup")
async def start_scheduler():
    scheduler.add_job(refresh_all_predictions, "interval", minutes=15)
    scheduler.start()
```

---

## Contributing

1. Fork the repo and create a feature branch (`git checkout -b feature/my-feature`).
2. Backend changes: add tests in `backend/tests/` (pytest).
3. Frontend changes: run `npx expo start` and test on both Android and iOS.
4. Open a pull request with a clear description of what changed and why.

---

## Licence

MIT © FloodSense University Project Team
