import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import Constants from 'expo-constants';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: true,
  }),
});

export async function registerForPushNotifications(): Promise<string | null> {
  let token: string | null = null;

  if (Platform.OS === 'android') {
    await Notifications.setNotificationChannelAsync('flood-alerts', {
      name: 'Flood Alerts',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: '#4A90D9',
    });
  }

  const { status: existingStatus } = await Notifications.getPermissionsAsync();
  let finalStatus = existingStatus;

  if (existingStatus !== 'granted') {
    const { status } = await Notifications.requestPermissionsAsync();
    finalStatus = status;
  }

  if (finalStatus !== 'granted') {
    console.log('[NotificationService] Push notification permission not granted');
    return null;
  }

  // Find EAS project ID if configured
  const projectId =
    Constants.expoConfig?.extra?.eas?.projectId ??
    Constants.easConfig?.projectId;

  try {
    if (projectId && projectId !== 'YOUR_EAS_PROJECT_ID') {
      const tokenData = await Notifications.getExpoPushTokenAsync({ projectId });
      token = tokenData.data;
    } else {
      // For local development on emulators without EAS credentials, use a placeholder token
      token = 'ExponentPushToken[emulator_dev_token]';
      console.log('[NotificationService] Using dev push token for local emulator/testing');
    }
  } catch (err) {
    token = 'ExponentPushToken[emulator_dev_token]';
    console.log('[NotificationService] Local dev token active');
  }

  return token;
}

export function setupNotificationListeners(): void {
  Notifications.addNotificationReceivedListener((notification) => {
    console.log('[NotificationService] Foreground notification received:', notification);
  });

  Notifications.addNotificationResponseReceivedListener((response) => {
    console.log('[NotificationService] Notification response:', response);
  });
}

export async function sendLocalNotification(title: string, body: string): Promise<void> {
  await Notifications.scheduleNotificationAsync({
    content: {
      title,
      body,
      sound: 'default',
      data: { type: 'flood_alert' },
    },
    trigger: null, // show immediately
  });
}
