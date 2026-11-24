import axios from 'axios';
import { API_BASE_URL } from '../constants/api';
import { StationReading, FloodRiskScore, UserProfile } from '../types';

const client = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: { 'Content-Type': 'application/json' },
});

export async function fetchStations(): Promise<StationReading[] | null> {
  try {
    const res = await client.get<StationReading[]>('/stations/');
    return res.data;
  } catch (err) {
    console.warn('[ApiService] fetchStations error:', err);
    return null;
  }
}

export async function fetchStation(id: string): Promise<StationReading | null> {
  try {
    const res = await client.get<StationReading>(`/stations/${id}`);
    return res.data;
  } catch (err) {
    console.warn('[ApiService] fetchStation error:', err);
    return null;
  }
}

export async function fetchStationHistory(id: string): Promise<StationReading[] | null> {
  try {
    const res = await client.get<StationReading[]>(`/stations/${id}/history`);
    return res.data;
  } catch (err) {
    console.warn('[ApiService] fetchStationHistory error:', err);
    return null;
  }
}

export async function submitPredictionRequest(payload: object): Promise<FloodRiskScore | null> {
  try {
    const res = await client.post<FloodRiskScore>('/predict', payload);
    return res.data;
  } catch (err) {
    console.warn('[ApiService] submitPredictionRequest error:', err);
    return null;
  }
}

export async function createUser(profile: UserProfile): Promise<UserProfile | null> {
  try {
    const res = await client.post<UserProfile>('/users/', profile);
    return res.data;
  } catch (err) {
    console.warn('[ApiService] createUser error:', err);
    return null;
  }
}

export async function updateUser(id: string, partial: Partial<UserProfile>): Promise<UserProfile | null> {
  try {
    const res = await client.put<UserProfile>(`/users/${id}`, partial);
    return res.data;
  } catch (err) {
    console.warn('[ApiService] updateUser error:', err);
    return null;
  }
}

export async function updateUserLocation(
  id: string,
  lat: number,
  lng: number
): Promise<void> {
  try {
    await client.post(`/users/${id}/location`, {
      user_id: id,
      lat,
      lng,
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    console.warn('[ApiService] updateUserLocation error:', err);
  }
}
