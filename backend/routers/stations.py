from __future__ import annotations

import math
import random
from datetime import datetime, timezone
from typing import Dict, List

from fastapi import APIRouter, HTTPException

from models import StationReading

router = APIRouter()


def _risk_label(water_level_m: float) -> str:
    if water_level_m < 2.5:
        return "Safe"
    elif water_level_m <= 4.0:
        return "Warning"
    else:
        return "Danger"


# Mock Malaysian river stations with realistic coordinates
_STATIONS: List[Dict] = [
    {
        "station_id": "SGK001",
        "station_name": "Sg. Klang @ Sulaiman",
        "river_name": "Sungai Klang",
        "lat": 3.1478,
        "lng": 101.6953,
        "water_level_m": 3.2,
        "rainfall_mm3": 45.5,
    },
    {
        "station_id": "SGB001",
        "station_name": "Sg. Gombak @ Jln Ipoh",
        "river_name": "Sungai Gombak",
        "lat": 3.1760,
        "lng": 101.6900,
        "water_level_m": 1.8,
        "rainfall_mm3": 12.0,
    },
    {
        "station_id": "SGBatu001",
        "station_name": "Sg. Batu @ Sentul",
        "river_name": "Sungai Batu",
        "lat": 3.1850,
        "lng": 101.6800,
        "water_level_m": 4.5,
        "rainfall_mm3": 88.3,
    },
    {
        "station_id": "SGL001",
        "station_name": "Sg. Langat @ Kajang",
        "river_name": "Sungai Langat",
        "lat": 2.9930,
        "lng": 101.7867,
        "water_level_m": 2.0,
        "rainfall_mm3": 20.1,
    },
    {
        "station_id": "SGS001",
        "station_name": "Sg. Selangor @ Rasa",
        "river_name": "Sungai Selangor",
        "lat": 3.4820,
        "lng": 101.5370,
        "water_level_m": 1.3,
        "rainfall_mm3": 5.6,
    },
]


def _make_reading(station: Dict) -> StationReading:
    return StationReading(
        station_id=station["station_id"],
        station_name=station["station_name"],
        river_name=station["river_name"],
        water_level_m=station["water_level_m"],
        rainfall_mm3=station["rainfall_mm3"],
        timestamp=datetime.now(timezone.utc),
    )


def _station_index() -> Dict[str, Dict]:
    return {s["station_id"]: s for s in _STATIONS}


@router.get("/", response_model=List[dict])
def list_stations():
    result = []
    for s in _STATIONS:
        entry = dict(s)
        entry["risk_label"] = _risk_label(s["water_level_m"])
        entry["timestamp"] = datetime.now(timezone.utc).isoformat()
        result.append(entry)
    return result


@router.get("/{station_id}", response_model=dict)
def get_station(station_id: str):
    idx = _station_index()
    if station_id not in idx:
        raise HTTPException(status_code=404, detail="Station not found")
    s = idx[station_id]
    entry = dict(s)
    entry["risk_label"] = _risk_label(s["water_level_m"])
    entry["timestamp"] = datetime.now(timezone.utc).isoformat()
    return entry


@router.get("/{station_id}/history", response_model=dict)
def get_station_history(station_id: str):
    idx = _station_index()
    if station_id not in idx:
        raise HTTPException(status_code=404, detail="Station not found")
    s = idx[station_id]
    base_wl = s["water_level_m"]
    base_rain = s["rainfall_mm3"]

    random.seed(station_id)
    water_history = [
        round(max(0.0, base_wl + random.uniform(-0.5, 0.5)), 2)
        for _ in range(24)
    ]
    rain_history = [
        round(max(0.0, base_rain + random.uniform(-10, 10)), 2)
        for _ in range(24)
    ]

    return {
        "station_id": station_id,
        "water_level_history": water_history,
        "rainfall_history": rain_history,
        "hours": list(range(-23, 1)),
    }
