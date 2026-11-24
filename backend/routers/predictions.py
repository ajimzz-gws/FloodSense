from __future__ import annotations

import random
from datetime import datetime, timezone
from typing import List

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from models import FloodRiskScore

router = APIRouter()


class PredictRequest(BaseModel):
    station_id: str
    water_level_history: List[float]
    rainfall_history: List[float]


def _map_label(score: float) -> str:
    if score < 0.4:
        return "Safe"
    elif score < 0.7:
        return "Warning"
    else:
        return "Danger"


@router.post("/predict", response_model=FloodRiskScore)
def predict(req: PredictRequest):
    last6_water = req.water_level_history[-6:] if len(req.water_level_history) >= 6 else req.water_level_history
    last6_rain = req.rainfall_history[-6:] if len(req.rainfall_history) >= 6 else req.rainfall_history

    if not last6_water or not last6_rain:
        raise HTTPException(status_code=422, detail="Insufficient history data")

    mean_water = sum(last6_water) / len(last6_water)
    mean_rain = sum(last6_rain) / len(last6_rain)

    # Placeholder LSTM formula
    risk_score = min(1.0, mean_water / 5.0 + mean_rain / 200.0)
    risk_label = _map_label(risk_score)

    return FloodRiskScore(
        station_id=req.station_id,
        risk_score=round(risk_score, 4),
        risk_label=risk_label,
        water_level_history=req.water_level_history,
        rainfall_history=req.rainfall_history,
        predicted_at=datetime.now(timezone.utc),
    )


@router.get("/latest/{station_id}", response_model=FloodRiskScore)
def get_latest_prediction(station_id: str):
    # Mock response for demo
    random.seed(station_id + datetime.now(timezone.utc).strftime("%Y%m%d%H"))
    water_history = [round(random.uniform(0.5, 5.0), 2) for _ in range(24)]
    rain_history = [round(random.uniform(0.0, 100.0), 2) for _ in range(24)]

    last6_water = water_history[-6:]
    last6_rain = rain_history[-6:]
    mean_water = sum(last6_water) / len(last6_water)
    mean_rain = sum(last6_rain) / len(last6_rain)
    risk_score = min(1.0, mean_water / 5.0 + mean_rain / 200.0)
    risk_label = _map_label(risk_score)

    return FloodRiskScore(
        station_id=station_id,
        risk_score=round(risk_score, 4),
        risk_label=risk_label,
        water_level_history=water_history,
        rainfall_history=rain_history,
        predicted_at=datetime.now(timezone.utc),
    )
