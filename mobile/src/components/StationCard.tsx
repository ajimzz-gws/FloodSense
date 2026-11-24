import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { StationReading } from '../types';
import RiskBadge from './RiskBadge';
import { COLORS, FONTS, SPACING } from '../constants/theme';

interface StationCardProps {
  station: StationReading;
  onPress?: () => void;
}

export default function StationCard({ station }: StationCardProps) {
  return (
    <View style={styles.card}>
      <Text style={styles.stationName}>{station.station_name}</Text>
      <Text style={styles.riverName}>{station.river_name}</Text>
      <View style={styles.row}>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{station.water_level_m.toFixed(2)} m</Text>
          <Text style={styles.metricLabel}>Water Level</Text>
        </View>
        <View style={styles.metric}>
          <Text style={styles.metricValue}>{station.rainfall_mm3.toFixed(1)} mm³</Text>
          <Text style={styles.metricLabel}>Rainfall</Text>
        </View>
      </View>
      {station.risk_label && (
        <View style={styles.badgeRow}>
          <RiskBadge riskLabel={station.risk_label} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: COLORS.background,
    borderRadius: 12,
    padding: SPACING.md,
    marginVertical: SPACING.sm,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 3,
  },
  stationName: {
    fontSize: FONTS.subtitle,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: SPACING.xs,
  },
  riverName: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginBottom: SPACING.sm,
  },
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: SPACING.sm,
  },
  metric: {
    flex: 1,
  },
  metricValue: {
    fontSize: FONTS.subtitle,
    fontWeight: '600',
    color: COLORS.primaryDark,
  },
  metricLabel: {
    fontSize: FONTS.small,
    color: COLORS.textSecondary,
  },
  badgeRow: {
    marginTop: SPACING.xs,
  },
});
