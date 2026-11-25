# FloodSense Backend

A FastAPI-based backend for the FloodSense flood risk monitoring application.

## Setup

### Prerequisites
- Python 3.11+
- pip

### Installation

```bash
cd backend
pip install -r requirements.txt
```

### Running the Server

```bash
python main.py
# or
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://localhost:8000`.  
Interactive docs: `http://localhost:8000/docs` (`/` redirects there)

> **Status:** paused. The Flutter app (`../mobile_flutter`) runs on hardcoded river data and
> does not call this backend yet.

---

## Endpoints

### Health
| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service health check |

---

### Users (`/users`)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/users/` | Create a new user profile |
| GET | `/users/{user_id}` | Get a user profile by ID |
| PUT | `/users/{user_id}` | Update a user profile |
| POST | `/users/{user_id}/location` | Update user's last known location |

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

---

### Stations (`/stations`)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/stations/` | List all 5 mock Malaysian river stations |
| GET | `/stations/{station_id}` | Get a single station reading |
| GET | `/stations/{station_id}/history` | Get 24-hour history arrays |

**Station IDs:** `SGK001`, `SGB001`, `SGBatu001`, `SGL001`, `SGS001`

**Risk labels:** `Safe` (< 2.5 m), `Warning` (2.5–4.0 m), `Danger` (> 4.0 m)

---

### Predictions (`/predictions`)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/predictions/predict` | Run placeholder LSTM risk prediction |
| GET | `/predictions/latest/{station_id}` | Fetch latest mock prediction |

**POST /predictions/predict body:**
```json
{
  "station_id": "SGK001",
  "water_level_history": [1.2, 1.5, 2.0, 2.3, 2.8, 3.1],
  "rainfall_history": [5.0, 10.0, 15.0, 20.0, 25.0, 30.0]
}
```

**Risk score formula (placeholder LSTM):**
```
risk_score = min(1.0, mean(last_6_water) / 5.0 + mean(last_6_rain) / 200.0)
```

**Risk label mapping:** `< 0.4 → Safe`, `0.4–0.7 → Warning`, `≥ 0.7 → Danger`

---

### Notifications (`/notifications`)
| Method | Path | Description |
|--------|------|-------------|
| POST | `/notifications/trigger` | Find all users inside Danger alert areas and log them (push pending) |
| POST | `/notifications/send` | Send a push notification to one user (returns 501 until push is configured) |

**POST /notifications/send body:**
```json
{
  "user_id": "u001",
  "title": "Flood Warning",
  "body": "Water levels rising near your area.",
  "data": {"type": "flood_warning"}
}
```

> **Push delivery is not configured yet.** The Flutter app currently raises alerts on the phone.
> The planned design is **Firebase Cloud Messaging (FCM) topics**, one topic per alert zone,
> so the server sends one message per zone instead of looping over users.
> `/notifications/trigger` already finds affected users and logs them with status `not_configured`.

---

## Project Structure

```
backend/
├── main.py                  # FastAPI app entrypoint
├── models.py                # Pydantic data models
├── requirements.txt         # Python dependencies
├── README.md                # This file
└── routers/
    ├── __init__.py
    ├── users.py             # User CRUD + location update
    ├── stations.py          # Station readings & history
    ├── predictions.py       # Flood risk prediction
    └── notifications.py     # Push notification dispatch
```

---

## Data Models

| Model | Key Fields |
|-------|-----------|
| `UserProfile` | id, name, email, home_address, selected_station_id, alert_areas, push_token, lat/lng |
| `StationReading` | station_id, station_name, river_name, water_level_m, rainfall_mm3, timestamp |
| `FloodRiskScore` | station_id, risk_score (0–1), risk_label, histories, predicted_at |
| `LocationUpdate` | user_id, lat, lng, timestamp |
| `NotificationPayload` | user_id, title, body, data |
| `AlertArea` | area_id, name, lat, lng, radius_km, risk_level |
