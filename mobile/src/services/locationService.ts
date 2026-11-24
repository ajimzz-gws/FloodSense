import * as Location from 'expo-location';
import * as TaskManager from 'expo-task-manager';
import axios from 'axios';
import { API_BASE_URL } from '../constants/api';

const BACKGROUND_LOCATION_TASK = 'BACKGROUND_LOCATION_TASK';

TaskManager.defineTask(BACKGROUND_LOCATION_TASK, async ({ data, error }: TaskManager.TaskManagerTaskBody) => {
  if (error) {
    console.error('[LocationService] Background task error:', error);
    return;
  }
  if (data) {
    const { locations } = data as { locations: Location.LocationObject[] };
    if (locations && locations.length > 0) {
      const { latitude, longitude } = locations[0].coords;
      const userId = (global as any).__floodsenseUserId;
      if (userId) {
        try {
          await axios.post(`${API_BASE_URL}/users/${userId}/location`, {
            user_id: userId,
            lat: latitude,
            lng: longitude,
            timestamp: new Date().toISOString(),
          });
        } catch (err) {
          console.warn('[LocationService] Failed to update location:', err);
        }
      }
    }
  }
});

export async function requestLocationPermissions(): Promise<boolean> {
  const { status: foregroundStatus } = await Location.requestForegroundPermissionsAsync();
  if (foregroundStatus !== 'granted') {
    console.warn('[LocationService] Foreground location permission denied');
    return false;
  }
  const { status: backgroundStatus } = await Location.requestBackgroundPermissionsAsync();
  if (backgroundStatus !== 'granted') {
    console.warn('[LocationService] Background location permission denied');
    return false;
  }
  return true;
}

export async function startBackgroundLocationTracking(userId: string): Promise<void> {
  (global as any).__floodsenseUserId = userId;
  const isRegistered = await TaskManager.isTaskRegisteredAsync(BACKGROUND_LOCATION_TASK);
  if (!isRegistered) {
    await Location.startLocationUpdatesAsync(BACKGROUND_LOCATION_TASK, {
      accuracy: Location.Accuracy.Balanced,
      timeInterval: 30000,
      distanceInterval: 50,
      showsBackgroundLocationIndicator: true,
      foregroundService: {
        notificationTitle: 'FloodSense',
        notificationBody: 'Monitoring your location for flood alerts',
        notificationColor: '#4A90D9',
      },
    });
  }
}

export async function stopBackgroundLocationTracking(): Promise<void> {
  const isRegistered = await TaskManager.isTaskRegisteredAsync(BACKGROUND_LOCATION_TASK);
  if (isRegistered) {
    await Location.stopLocationUpdatesAsync(BACKGROUND_LOCATION_TASK);
  }
}

export async function getCurrentLocation(): Promise<{ lat: number; lng: number }> {
  const location = await Location.getCurrentPositionAsync({
    accuracy: Location.Accuracy.Balanced,
  });
  return {
    lat: location.coords.latitude,
    lng: location.coords.longitude,
  };
}
