from __future__ import annotations

from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel


class UserProfile(BaseModel):
    id: str
    name: str
    email: str
    home_address: str
    selected_station_id: str
    alert_areas: List[str]
    push_token: Optional[str] = None
    last_known_lat: Optional[float] = None
    last_known_lng: Optional[float] = None


class StationReading(BaseModel):
    station_id: str
    station_name: str
    river_name: str
    water_level_m: float
    rainfall_mm3: float
    timestamp: datetime


class FloodRiskScore(BaseModel):
    station_id: str
    risk_score: float  # 0.0 - 1.0
    risk_label: str    # "Safe" | "Warning" | "Danger"
    water_level_history: List[float]
    rainfall_history: List[float]
    predicted_at: datetime


class LocationUpdate(BaseModel):
    user_id: str
    lat: float
    lng: float
    timestamp: datetime


class NotificationPayload(BaseModel):
    user_id: str
    title: str
    body: str
    data: Dict


class AlertArea(BaseModel):
    area_id: str
    name: str
    lat: float
    lng: float
    radius_km: float
    risk_level: str  # "Safe" | "Warning" | "Danger"
