import React, { useEffect } from 'react';
import { StatusBar, Platform, View, ActivityIndicator } from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useFonts } from 'expo-font';

import HomeScreen from './src/screens/HomeScreen';
import MapScreen from './src/screens/MapScreen';
import ProfileScreen from './src/screens/ProfileScreen';

import { registerForPushNotifications, setupNotificationListeners } from './src/services/notificationService';
import { requestLocationPermissions } from './src/services/locationService';
import { COLORS, FONTS } from './src/constants/theme';

const Tab = createBottomTabNavigator();

export default function App() {
  const [fontsLoaded] = useFonts({
    ionicons: require('@expo/vector-icons/build/vendor/react-native-vector-icons/Fonts/Ionicons.ttf'),
  });

  useEffect(() => {
    (async () => {
      try {
        await requestLocationPermissions();
        const token = await registerForPushNotifications();
        if (token) console.log('[App] Push token:', token);
        setupNotificationListeners();
      } catch (err) {
        console.warn('[App] Permission/Push setup error:', err);
      }
    })();
  }, []);

  if (!fontsLoaded) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: COLORS.background }}>
        <ActivityIndicator size="large" color={COLORS.primary} />
      </View>
    );
  }

  return (
    <>
      <StatusBar barStyle="dark-content" backgroundColor={COLORS.background} />
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={({ route }) => ({
            headerStyle: { backgroundColor: COLORS.background, elevation: 0, shadowOpacity: 0 },
            headerTitleStyle: { fontSize: FONTS.title, fontWeight: '700', color: COLORS.textPrimary },
            tabBarActiveTintColor: COLORS.primary,
            tabBarInactiveTintColor: COLORS.textSecondary,
            tabBarStyle: {
              backgroundColor: COLORS.background,
              height: 65,
              paddingBottom: Platform.OS === 'ios' ? 12 : 8,
              paddingTop: 6,
              borderTopWidth: 1,
              borderTopColor: '#E0E8F0',
              shadowColor: '#000',
              shadowOffset: { width: 0, height: -2 },
              shadowOpacity: 0.06,
              shadowRadius: 8,
              elevation: 8,
            },
            tabBarLabelStyle: {
              fontSize: 13,
              fontWeight: '600',
              marginTop: 2,
            },
            tabBarIcon: ({ focused, color, size }) => {
              let iconName: keyof typeof Ionicons.glyphMap = 'home-outline';
              if (route.name === 'Home') iconName = focused ? 'water' : 'water-outline';
              else if (route.name === 'Map') iconName = focused ? 'map' : 'map-outline';
              else if (route.name === 'Profile') iconName = focused ? 'person' : 'person-outline';
              return <Ionicons name={iconName} size={size} color={color} />;
            },
          })}
        >
          <Tab.Screen name="Home" component={HomeScreen} options={{ title: 'FloodSense' }} />
          <Tab.Screen name="Map" component={MapScreen} options={{ title: 'Station Map' }} />
          <Tab.Screen name="Profile" component={ProfileScreen} options={{ title: 'My Profile' }} />
        </Tab.Navigator>
      </NavigationContainer>
    </>
  );
}
