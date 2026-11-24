from __future__ import annotations

import math
from typing import Dict, List

import httpx
from fastapi import APIRouter, HTTPException

from models import AlertArea, NotificationPayload
from database import db_get_all_users, db_get_alert_areas, db_get_user, db_log_notification

router = APIRouter()

EXPO_PUSH_URL = "https://exp.host/--/api/v2/push/send"


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Return the great-circle distance in kilometres between two points."""
    R = 6371.0
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lam = math.radians(lng2 - lng1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lam / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _user_in_danger_area(lat: float, lng: float, alert_areas: List[dict]) -> bool:
    for area in alert_areas:
        if area.get("risk_level") == "Danger":
            dist = _haversine_km(lat, lng, area["lat"], area["lng"])
            if dist <= area["radius_km"]:
                return True
    return False


async def _send_expo_push(push_token: str, title: str, body: str, data: dict) -> dict:
    payload = {
        "to": push_token,
        "title": title,
        "body": body,
        "data": data,
        "sound": "default",
        "priority": "high",
    }
    async with httpx.AsyncClient(timeout=10.0) as client:
        resp = await client.post(EXPO_PUSH_URL, json=payload)
        return resp.json()


@router.post("/trigger", response_model=dict)
async def trigger_notifications():
    """Scan all users in Danger AlertAreas and send push notifications."""
    notified: List[str] = []
    errors: List[dict] = []

    users = db_get_all_users()
    alert_areas = db_get_alert_areas()

    for user in users:
        user_id = user["id"]
        lat = user.get("last_known_lat")
        lng = user.get("last_known_lng")
        push_token = user.get("push_token")

        if lat is None or lng is None:
            continue
        if not _user_in_danger_area(lat, lng, alert_areas):
            continue

        if not push_token:
            notified.append(f"{user_id} (flagged, no token)")
            db_log_notification(user_id, "🚨 Flood Danger Alert", "Flagged in Danger area", "no_token")
            continue

        try:
            resp = await _send_expo_push(
                push_token=push_token,
                title="🚨 Flood Danger Alert",
                body="You are near a flood danger zone. Please evacuate immediately.",
                data={"type": "flood_alert", "user_id": user_id},
            )
            notified.append(user_id)
            db_log_notification(user_id, "🚨 Flood Danger Alert", "Notification sent via Expo", "sent")
        except Exception as exc:
            errors.append({"user_id": user_id, "error": str(exc)})
            db_log_notification(user_id, "🚨 Flood Danger Alert", str(exc), "failed")

    return {
        "notified_count": len(notified),
        "notified_users": notified,
        "errors": errors,
    }


@router.post("/send", response_model=dict)
async def send_notification(payload: NotificationPayload):
    """Directly send a push notification to a specific user by user_id."""
    user = db_get_user(payload.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    push_token = user.get("push_token")
    if not push_token:
        raise HTTPException(status_code=400, detail="User has no registered push token")

    try:
        resp = await _send_expo_push(
            push_token=push_token,
            title=payload.title,
            body=payload.body,
            data=payload.data,
        )
        db_log_notification(payload.user_id, payload.title, payload.body, "sent")
        return {"status": "sent", "expo_response": resp}
    except Exception as exc:
        db_log_notification(payload.user_id, payload.title, payload.body, "failed")
        raise HTTPException(status_code=502, detail=f"Failed to send push notification: {exc}")
