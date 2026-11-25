# FloodSense 🌊

> **A flood early-warning app for river communities in Terengganu, Malaysia.**
> Built with **Flutter** (Android). The **FastAPI** backend is paused while the prototype runs on its own.

## 🎬 Demo Video

<!-- Replace VIDEO_ID with the YouTube video ID (the part after "v=" in the URL). -->
[![FloodSense demo video](https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg)](https://www.youtube.com/watch?v=VIDEO_ID)

▶️ **[Watch the demo on YouTube](https://www.youtube.com/watch?v=VIDEO_ID)** *(link coming soon)*

---

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Project Status](#project-status)
4. [Repository Structure](#repository-structure)
5. [Getting Started](#getting-started)
6. [Demo Walkthrough](#demo-walkthrough)
7. [Data Sources](#data-sources)
8. [How Alerts Work](#how-alerts-work)
9. [Accessibility](#accessibility)
10. [Testing](#testing)
11. [Backend (paused)](#backend-paused)
12. [Roadmap](#roadmap)

---

## Overview

FloodSense watches river water levels and warns people **in the affected area** when a river
rises toward flood levels. It uses the same four-stage scale as JPS / InfoBanjir:

| Stage | Malay | Colour | Meaning for the user |
|---|---|---|---|
| Normal | Normal | 🔵 Blue | No action needed |
| Alert | Waspada | 🟡 Yellow | Water is rising: stay alert |
| Warning | Amaran | 🟠 Orange | Get ready to leave |
| Danger | Bahaya | 🔴 Red | Leave now, go to the nearest relief centre (PPS) |

---

## Features

| Screen | What it does |
|---|---|
| **Home** | Your station's status in a large colour card, a **MET Malaysia weather forecast**, what to do now, a level gauge with thresholds, and whether you are inside the station's alert zone |
| **Stations** | All stations with their current level; tap one to make it "my station" |
| **Map** | OpenStreetMap with colour-coded station pins, 5 km alert zones and your location |
| **Settings** | English / Bahasa Melayu, three text sizes, location tracking, "always alert me about my station" |
| **Demo mode** | Set any water level, play a rising-flood scenario, or pretend to be at a station, to show the alerts |
| **Alerts** | Full-screen alert in the stage colour, plus a phone notification with vibration |

---

## Project Status

This is a **prototype** for a university project.

| Part | Status |
|---|---|
| River levels | **Hardcoded** from a real InfoBanjir reading (see [Data Sources](#data-sources)); changed live through Demo mode |
| Weather forecast | **Live** from MET Malaysia, with an offline fallback |
| Alerts | Decided **on the phone** (local notifications) |
| Location tracking | Continuous, as an Android foreground service |
| Backend | Paused; the app does not call it yet |
| Platforms | Android (tested on the Android emulator) |

---

## Repository Structure

```
FloodSense/
├── README.md                    ← this file
├── mobile_flutter/              ← Flutter app (the current app)
│   ├── lib/
│   │   ├── main.dart            # App entry, theme, bottom navigation, alert pop-up
│   │   ├── data/                # Hardcoded stations and thresholds
│   │   ├── models/              # Station, flood levels, weather forecast
│   │   ├── services/            # Alert rules, location, notifications, MET weather
│   │   ├── state/               # App state (Provider)
│   │   ├── screens/             # Home, Stations, Map, Settings, Demo, Alert
│   │   ├── widgets/             # Level gauge, threshold table, weather card
│   │   ├── l10n/                # English and Bahasa Melayu text
│   │   └── theme/               # Colours, text sizes, level styles
│   ├── test/                    # Unit tests
│   ├── assets/icon/             # App icon source (FloodSense logo)
│   └── README.md                # App-specific notes
└── backend/                     ← FastAPI backend (paused)
```

---

## Getting Started

### Prerequisites
- **Flutter 3.41+** (Dart 3.11+): check with `flutter doctor`
- **Android Studio** with an Android emulator, or an Android phone with USB debugging

### Run the app

```bash
cd mobile_flutter
flutter pub get
flutter emulators --launch Medium_Phone   # or plug in a phone
flutter run --release
```

> **Tip:** use `--release` on low-memory emulators (2 GB). Debug builds use about twice the RAM,
> and Android may close the app.

### Build an APK to share

```bash
cd mobile_flutter
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

On first launch the app asks for **location** and **notification** permission. Both are needed
for area alerts.

---

## Demo Walkthrough

1. **Home** shows *Sg. Terengganu di Drawbridge (F1)* at **Normal, −0.30 m**, with today's MET forecast.
2. Tap **Demo mode** (top right).
3. Tap **Alert**, **Warning** or **Danger**, or press **Play rising flood** to raise the water step by step.
4. Each time the river moves *up* a stage, a **full-screen alert** and a **notification** appear.
5. Not near the station? Turn on **Pretend I am at this station**. On the emulator you can also
   set the GPS near the station: `adb emu geo fix 103.1500 5.3300`.
6. **Reset all to real data** puts every station back to its real reading.

---

## Data Sources

### River levels: InfoBanjir (JPS Malaysia)
Reading taken from [publicinfobanjir.water.gov.my](https://publicinfobanjir.water.gov.my) on **24/11/2026 14:00**:

| Station ID | Station | District | Current | Normal | Alert | Warning | Danger |
|---|---|---|---|---|---|---|---|
| 0670341WL | Sg. Terengganu di Drawbridge (F1) | Kuala Terengganu | −0.30 m | 0.30 m | 1.40 m | 1.60 m | 1.80 m |

Three more stations (Besut, Dungun, Kemaman) are **sample data** with made-up readings, so the map and
list have something to compare. The app labels them "Sample data". All station data lives in
`mobile_flutter/lib/data/stations_data.dart`.

### Weather: MET Malaysia
7-day general forecast from MET Malaysia, published on the government open data API
([`api.data.gov.my/weather/forecast`](https://developer.data.gov.my/realtime-api/weather)); it needs no API key.
Each station uses its district forecast (e.g. `Ds048` = Kuala Terengganu). MET publishes the text
in Malay; the app translates it for English users and keeps the last forecast for offline use.

---

## How Alerts Work

**Who is alerted:** everyone **within 5 km** of a station (its alert zone), plus anyone who picked it
as "my station" (optional setting, e.g. for a family member's area).

**When:** once each time the river moves **up** a stage (Normal → Alert → Warning → Danger).
There are no repeats while the level stays the same. When the water falls, the app forgets the higher
stage, so a second rise alerts again. Someone who walks into a zone that is already at Warning is
alerted straight away.

These rules live in `mobile_flutter/lib/services/alert_engine.dart` and are covered by unit tests.

**Planned server design:** **Firebase Cloud Messaging topics**, one per alert zone. Phones subscribe
to a zone's topic when they enter it and unsubscribe when they leave. When a station crosses a
threshold, the server sends **one message to the topic** and every phone in the area gets the same
alert. The server never needs a list of users or their locations.

---

## Accessibility

Designed to be usable by all ages:
- Each stage is shown by **colour, icon and word**, so it does not rely on colour alone
- Text colours meet **WCAG AA** contrast
- Large base font sizes, plus **Normal / Large / Extra large** text settings on top of the phone's own setting
- Touch targets of at least **56 dp**, and bottom navigation labels that are always visible
- **English and Bahasa Melayu**, using the official JPS stage names (Waspada, Amaran, Bahaya)
- Plain-language "what you should do" advice for every stage
- Screen-reader labels on the status card, gauge and map pins

---

## Testing

```bash
cd mobile_flutter
flutter test      # thresholds, alert rules, MET forecast translation
flutter analyze   # static analysis
```

---

## Backend (paused)

`backend/` is a **FastAPI** service with station, user, prediction and notification endpoints, using
SQLite for storage. The Flutter prototype does not call it yet. Push delivery is not configured: the
Danger-zone check works, and Firebase (FCM) is the planned provider. See
[`backend/README.md`](backend/README.md) for setup and endpoints.

```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload   # docs at http://localhost:8000/docs
```

---

## Roadmap

- [ ] **Live river levels** from InfoBanjir instead of hardcoded readings
- [ ] **Firebase Cloud Messaging** topic alerts per zone (server-side), as described above
- [ ] Connect the app to the **backend** (user profiles, alert zones, history)
- [ ] **Flood risk prediction** (LSTM on water level + rainfall history, replacing the placeholder formula in `backend/routers/predictions.py`)
- [ ] Map tiles from a production tile provider (OpenStreetMap's public tiles are fine for a demo only)
- [ ] Nearest relief centre (PPS) directions in Danger alerts
- [ ] iOS build

---

## Licence

MIT © FloodSense University Project Team
