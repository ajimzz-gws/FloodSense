export interface UserProfile {
  id: string;
  name: string;
  email: string;
  home_address: string;
  selected_station_id: string;
  alert_areas: string[];
  push_token?: string | null;
  last_known_lat?: number | null;
  last_known_lng?: number | null;
}

export interface StationReading {
  station_id: string;
  station_name: string;
  river_name: string;
  water_level_m: number;
  rainfall_mm3: number;
  timestamp: string;
  risk_label?: 'Safe' | 'Warning' | 'Danger';
}

export interface FloodRiskScore {
  station_id: string;
  risk_score: number;
  risk_label: 'Safe' | 'Warning' | 'Danger';
  water_level_history: number[];
  rainfall_history: number[];
  predicted_at: string;
}

export interface AlertArea {
  area_id: string;
  name: string;
  lat: number;
  lng: number;
  radius_km: number;
  risk_level: string;
}

export interface LocationUpdate {
  user_id: string;
  lat: number;
  lng: number;
  timestamp: string;
}
