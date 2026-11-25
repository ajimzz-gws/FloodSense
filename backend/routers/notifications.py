from __future__ import annotations

import math
from typing import List

from fastapi import APIRouter, HTTPException

from models import NotificationPayload
from database import db_get_all_users, db_get_alert_areas, db_get_user, db_log_notification

router = APIRouter()

# Push delivery is not wired up yet.
#
# The Flutter app currently raises flood alerts on the phone itself.
# The planned server-side design is Firebase Cloud Messaging (FCM) topics:
# one topic per alert zone (e.g. "zone_0670341WL"), which phones subscribe to
# when they enter the zone. The server then sends ONE message per topic when
# a station crosses a threshold, instead of looping over individual users.
# See mobile_flutter/README.md -> "Alert rule".


class PushNotConfigured(RuntimeError):
    """Raised until a push provider (FCM) is configured."""


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


async def _send_push(push_token: str, title: str, body: str, data: dict) -> dict:
    """Deliver a push notification. Placeholder until FCM is added."""
    raise PushNotConfigured("Push delivery is not configured (FCM pending)")


@router.post("/trigger", response_model=dict)
async def trigger_notifications():
    """Find every user inside a Danger alert area and try to notify them.

    Until push delivery is configured, affected users are still found and
    logged with status "not_configured", so the zone logic can be tested.
    """
    affected: List[str] = []
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

        affected.append(user_id)
        if not push_token:
            db_log_notification(user_id, "Flood Danger Alert", "In Danger area, no push token", "no_token")
            continue

        try:
            await _send_push(
                push_token=push_token,
                title="Flood Danger Alert",
                body="You are near a flood danger zone. Please evacuate immediately.",
                data={"type": "flood_alert", "user_id": user_id},
            )
            db_log_notification(user_id, "Flood Danger Alert", "Notification sent", "sent")
        except PushNotConfigured as exc:
            db_log_notification(user_id, "Flood Danger Alert", str(exc), "not_configured")
        except Exception as exc:
            errors.append({"user_id": user_id, "error": str(exc)})
            db_log_notification(user_id, "Flood Danger Alert", str(exc), "failed")

    return {
        "affected_count": len(affected),
        "affected_users": affected,
        "push_configured": False,
        "errors": errors,
    }


@router.post("/send", response_model=dict)
async def send_notification(payload: NotificationPayload):
    """Send a push notification to one user (needs a push provider)."""
    user = db_get_user(payload.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    push_token = user.get("push_token")
    if not push_token:
        raise HTTPException(status_code=400, detail="User has no registered push token")

    try:
        resp = await _send_push(
            push_token=push_token,
            title=payload.title,
            body=payload.body,
            data=payload.data,
        )
        db_log_notification(payload.user_id, payload.title, payload.body, "sent")
        return {"status": "sent", "response": resp}
    except PushNotConfigured as exc:
        db_log_notification(payload.user_id, payload.title, payload.body, "not_configured")
        raise HTTPException(status_code=501, detail=str(exc))
    except Exception as exc:
        db_log_notification(payload.user_id, payload.title, payload.body, "failed")
        raise HTTPException(status_code=502, detail=f"Failed to send push notification: {exc}")
