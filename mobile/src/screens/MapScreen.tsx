import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import MapView, { Marker, Callout, Circle } from 'react-native-maps';
import { StationReading } from '../types';
import { fetchStations } from '../services/apiService';
import { getCurrentLocation, requestLocationPermissions } from '../services/locationService';
import { COLORS, FONTS, SPACING } from '../constants/theme';

const MALAYSIA_REGION = {
  latitude: 3.139,
  longitude: 101.6869,
  latitudeDelta: 1.0,
  longitudeDelta: 1.0,
};

const markerColor: Record<string, string> = {
  Safe: COLORS.safe,
  Warning: COLORS.warning,
  Danger: COLORS.danger,
};

const legendItems: { label: string; color: string }[] = [
  { label: 'Safe', color: COLORS.safe },
  { label: 'Warning', color: COLORS.warning },
  { label: 'Danger', color: COLORS.danger },
];

export default function MapScreen() {
  const [stations, setStations] = useState<StationReading[]>([]);
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null);
  const [mapLoading, setMapLoading] = useState(true);

  useEffect(() => {
    (async () => {
      const data = await fetchStations();
      if (data) setStations(data);

      const hasPermission = await requestLocationPermissions();
      if (hasPermission) {
        try {
          const loc = await getCurrentLocation();
          setUserLocation(loc);
        } catch (e) {
          console.warn('[MapScreen] Could not get user location:', e);
        }
      }
      setMapLoading(false);
    })();
  }, []);

  if (mapLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Loading map…</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <MapView style={styles.map} initialRegion={MALAYSIA_REGION}>
        {stations.map((station) => {
          const color = markerColor[station.risk_label ?? 'Safe'] ?? COLORS.safe;
          // Stations from backend have coords; use fallback if missing
          const lat = (station as any).lat ?? 3.139;
          const lng = (station as any).lng ?? 101.6869;
          return (
            <Marker
              key={station.station_id}
              coordinate={{ latitude: lat, longitude: lng }}
              pinColor={color}
              title={station.station_name}
            >
              <Callout>
                <View style={styles.callout}>
                  <Text style={styles.calloutTitle}>{station.station_name}</Text>
                  <Text style={styles.calloutRow}>River: {station.river_name}</Text>
                  <Text style={styles.calloutRow}>
                    Water Level: {station.water_level_m.toFixed(2)} m
                  </Text>
                  <Text style={styles.calloutRow}>
                    Rainfall: {station.rainfall_mm3.toFixed(1)} mm³
                  </Text>
                  <Text style={[styles.calloutRisk, { color }]}>
                    {station.risk_label ?? 'Safe'}
                  </Text>
                </View>
              </Callout>
            </Marker>
          );
        })}

        {userLocation && (
          <>
            <Marker
              coordinate={{ latitude: userLocation.lat, longitude: userLocation.lng }}
              pinColor={COLORS.primary}
              title="Your Location"
            />
            <Circle
              center={{ latitude: userLocation.lat, longitude: userLocation.lng }}
              radius={500}
              fillColor="rgba(74,144,217,0.15)"
              strokeColor="rgba(74,144,217,0.5)"
              strokeWidth={2}
            />
          </>
        )}
      </MapView>

      {/* Legend */}
      <View style={styles.legend}>
        {legendItems.map((item) => (
          <View key={item.label} style={styles.legendRow}>
            <View style={[styles.legendDot, { backgroundColor: item.color }]} />
            <Text style={styles.legendLabel}>{item.label}</Text>
          </View>
        ))}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { ...StyleSheet.absoluteFillObject },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: COLORS.background,
  },
  loadingText: {
    marginTop: SPACING.md,
    fontSize: FONTS.subtitle,
    color: COLORS.textSecondary,
  },
  callout: {
    minWidth: 180,
    padding: SPACING.sm,
  },
  calloutTitle: {
    fontSize: FONTS.subtitle,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: SPACING.xs,
  },
  calloutRow: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginBottom: 2,
  },
  calloutRisk: {
    fontSize: FONTS.subtitle,
    fontWeight: '700',
    marginTop: SPACING.xs,
  },
  legend: {
    position: 'absolute',
    bottom: 32,
    left: 16,
    backgroundColor: 'rgba(255,255,255,0.95)',
    borderRadius: 12,
    padding: SPACING.md,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 4,
  },
  legendRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: SPACING.xs,
  },
  legendDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    marginRight: SPACING.sm,
  },
  legendLabel: {
    fontSize: FONTS.body,
    color: COLORS.textPrimary,
    fontWeight: '500',
  },
});
