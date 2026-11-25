# FloodSense (Flutter prototype)

Flood alert app for Terengganu river stations. **Prototype:** all data is hardcoded and
the app runs without the backend.

**Live data:** the weather forecast comes from MET Malaysia via the government open data API,
so it needs internet. If the request fails, the app shows the last forecast it saved. River levels
are still hardcoded.

## Run

```powershell
flutter emulators --launch Medium_Phone
flutter run --release
```

Use `--release` on the 2 GB emulator. Debug builds use about twice the memory and Android's
low-memory killer may close the app.

## Demo script

1. **Home** shows Sg. Terengganu di Drawbridge (F1), 0670341WL: **Normal, −0.30 m**
   (InfoBanjir reading, 24/11/2026 14:00).
2. Tap **Demo mode** (top right), then tap **Alert / Warning / Danger**, or press **Play rising flood**.
3. Each time the level moves *up* a stage, users in the impact zone get a full-screen alert and a
   phone notification. Turn on **Pretend I am at this station** if the phone is far away.
   In the emulator you can also set the GPS: `adb emu geo fix 103.1500 5.3300` (about 1 km from the station).
4. **Settings:** English / Bahasa Melayu, three text sizes, location tracking.

## Thresholds (0670341WL)

| Level | Range | Colour |
|---|---|---|
| Normal (Normal) | < 1.40 m (usual level 0.30 m) | blue |
| Alert (Waspada) | ≥ 1.40 m | yellow |
| Warning (Amaran) | ≥ 1.60 m | orange |
| Danger (Bahaya) | ≥ 1.80 m | red |

The other three stations (Besut, Dungun, Kemaman) are **sample data**, marked as such in the app.

## Code map

| Path | What |
|---|---|
| `lib/data/stations_data.dart` | Hardcoded stations and thresholds. Edit here to add stations |
| `lib/models/station.dart` | Station model and `classify()` (level → status) |
| `lib/services/alert_engine.dart` | Alert rules (pure Dart, unit tested) |
| `lib/state/app_state.dart` | App state: settings, location, demo controls, firing alerts |
| `lib/services/location_service.dart` | Continuous GPS via a foreground service |
| `lib/services/notification_service.dart` | System notifications |
| `lib/services/weather_service.dart` | 7-day MET Malaysia forecast from `api.data.gov.my/weather/forecast` (no key), cached for offline use |
| `lib/models/weather.dart` | Forecast model, Malay→English translation of MET phrases, rain severity |
| `lib/widgets/weather_card.dart` | Forecast card on Home (below the water level) |
| `assets/icon/` | App icon source (logo). Regenerate with `dart run flutter_launcher_icons` |
| `lib/l10n/strings.dart` | All English and Malay text |
| `lib/screens/` | Home, Stations, Map, Settings, Demo, full-screen Alert |
| `test/flood_logic_test.dart` | Threshold and alert-rule tests (`flutter test`) |

## Alert rule

Alert once per step up (Normal → Alert → Warning → Danger), only for people in the station's
5 km zone (plus anyone who picked it as their station, if that setting is on). Falling water
resets this, so a second rise alerts again.

**Production path (not built yet):** each zone becomes a Firebase Cloud Messaging topic. The phone
subscribes to a zone's topic when it enters the zone and unsubscribes when it leaves. The server sends
one message per topic when a station crosses a threshold. The UI and alert screen stay the same.
