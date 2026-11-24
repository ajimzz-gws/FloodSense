import { Platform } from 'react-native';

// On Android Emulator, 10.0.2.2 routes directly to host PC's localhost:8000.
// On physical devices or other platforms, it uses your LAN IP.
export const API_BASE_URL = 'http://10.0.2.2:8000';

export const getStations = () => `${API_BASE_URL}/stations/`;
export const getStation = (id: string) => `${API_BASE_URL}/stations/${id}`;
export const getStationHistory = (id: string) => `${API_BASE_URL}/stations/${id}/history`;
export const predict = (payload?: object) => `${API_BASE_URL}/predict`;
export const updateUserProfile = (id: string, data?: object) => `${API_BASE_URL}/users/${id}`;
export const updateLocation = (id: string, lat?: number, lng?: number) =>
  `${API_BASE_URL}/users/${id}/location`;
