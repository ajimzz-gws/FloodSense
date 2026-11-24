import sqlite3
import json
import os
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone

DB_PATH = os.path.join(os.path.dirname(__file__), "floodsense.db")


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_connection()
    cursor = conn.cursor()

    # Users Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        home_address TEXT,
        selected_station_id TEXT DEFAULT 'SGK001',
        alert_areas TEXT DEFAULT '[]',
        push_token TEXT,
        last_known_lat REAL,
        last_known_lng REAL,
        updated_at TEXT
    )
    """)

    # Alert Areas Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS alert_areas (
        area_id TEXT PRIMARY KEY,
        name TEXT,
        lat REAL,
        lng REAL,
        radius_km REAL,
        risk_level TEXT
    )
    """)

    # Notification Logs Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS notification_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        title TEXT,
        body TEXT,
        status TEXT,
        sent_at TEXT
    )
    """)

    # Populate default alert areas if empty
    cursor.execute("SELECT COUNT(*) FROM alert_areas")
    if cursor.fetchone()[0] == 0:
        default_areas = [
            ("AA001", "Sentul Flood Zone", 3.1850, 101.6800, 2.0, "Danger"),
            ("AA002", "Klang Valley Flood Zone", 3.1478, 101.6953, 3.0, "Warning"),
            ("AA003", "Kajang Riverside Zone", 2.9930, 101.7867, 2.5, "Safe"),
        ]
        cursor.executemany(
            "INSERT INTO alert_areas (area_id, name, lat, lng, radius_km, risk_level) VALUES (?, ?, ?, ?, ?, ?)",
            default_areas,
        )

    conn.commit()
    conn.close()


# User CRUD Operations
def db_create_user(user_data: Dict[str, Any]) -> Dict[str, Any]:
    conn = get_connection()
    cursor = conn.cursor()
    alert_areas_json = json.dumps(user_data.get("alert_areas", []))
    now = datetime.now(timezone.utc).isoformat()

    cursor.execute(
        """
        INSERT INTO users (id, name, email, home_address, selected_station_id, alert_areas, push_token, last_known_lat, last_known_lng, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            user_data["id"],
            user_data.get("name", ""),
            user_data.get("email", ""),
            user_data.get("home_address", ""),
            user_data.get("selected_station_id", "SGK001"),
            alert_areas_json,
            user_data.get("push_token"),
            user_data.get("last_known_lat"),
            user_data.get("last_known_lng"),
            now,
        ),
    )
    conn.commit()
    conn.close()
    return db_get_user(user_data["id"])


def db_get_user(user_id: str) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
    row = cursor.fetchone()
    conn.close()
    if not row:
        return None
    d = dict(row)
    d["alert_areas"] = json.loads(d.get("alert_areas") or "[]")
    return d


def db_update_user(user_id: str, user_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    alert_areas_json = json.dumps(user_data.get("alert_areas", []))
    now = datetime.now(timezone.utc).isoformat()

    cursor.execute(
        """
        UPDATE users
        SET name = ?, email = ?, home_address = ?, selected_station_id = ?, alert_areas = ?, push_token = ?, updated_at = ?
        WHERE id = ?
        """,
        (
            user_data.get("name", ""),
            user_data.get("email", ""),
            user_data.get("home_address", ""),
            user_data.get("selected_station_id", "SGK001"),
            alert_areas_json,
            user_data.get("push_token"),
            now,
            user_id,
        ),
    )
    conn.commit()
    conn.close()
    return db_get_user(user_id)


def db_update_user_location(user_id: str, lat: float, lng: float) -> Optional[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    now = datetime.now(timezone.utc).isoformat()

    # Create user with default profile if doesn't exist yet
    cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,))
    if not cursor.fetchone():
        cursor.execute(
            """
            INSERT INTO users (id, name, email, home_address, selected_station_id, alert_areas, push_token, last_known_lat, last_known_lng, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (user_id, "Mobile User", "", "", "SGK001", "[]", None, lat, lng, now),
        )
    else:
        cursor.execute(
            """
            UPDATE users
            SET last_known_lat = ?, last_known_lng = ?, updated_at = ?
            WHERE id = ?
            """,
            (lat, lng, now, user_id),
        )
    conn.commit()
    conn.close()
    return {"user_id": user_id, "lat": lat, "lng": lng, "updated_at": now}


def db_get_all_users() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM users")
    rows = cursor.fetchall()
    conn.close()
    users = []
    for row in rows:
        d = dict(row)
        d["alert_areas"] = json.loads(d.get("alert_areas") or "[]")
        users.append(d)
    return users


def db_get_alert_areas() -> List[Dict[str, Any]]:
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM alert_areas")
    rows = cursor.fetchall()
    conn.close()
    return [dict(r) for r in rows]


def db_log_notification(user_id: str, title: str, body: str, status: str):
    conn = get_connection()
    cursor = conn.cursor()
    now = datetime.now(timezone.utc).isoformat()
    cursor.execute(
        "INSERT INTO notification_logs (user_id, title, body, status, sent_at) VALUES (?, ?, ?, ?, ?)",
        (user_id, title, body, status, now),
    )
    conn.commit()
    conn.close()
