import React, { useEffect } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Dimensions,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useFloodData } from '../hooks/useFloodData';
import { useUserProfile } from '../hooks/useUserProfile';
import { COLORS, FONTS, SPACING } from '../constants/theme';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');
const BANNER_HEIGHT = SCREEN_HEIGHT * 0.25;

type RiskLabel = 'Safe' | 'Warning' | 'Danger';

const riskConfig: Record<RiskLabel, { bg: string; icon: string; lightBg: string }> = {
  Safe: { bg: COLORS.safe, icon: 'checkmark-circle', lightBg: COLORS.safeLight },
  Warning: { bg: COLORS.warning, icon: 'warning', lightBg: COLORS.warningLight },
  Danger: { bg: COLORS.danger, icon: 'alert-circle', lightBg: COLORS.dangerLight },
};

export default function HomeScreen() {
  const { stations, selectedStation, riskScore, loading, error, selectStation, refresh } =
    useFloodData();
  const { profile, loadProfile } = useUserProfile();

  useEffect(() => {
    loadProfile();
  }, [loadProfile]);

  useEffect(() => {
    if (profile?.selected_station_id && stations.length > 0) {
      selectStation(profile.selected_station_id);
    }
  }, [profile?.selected_station_id, stations.length]);

  if (loading) {
    return (
      <View style={styles.centeredContainer}>
        <ActivityIndicator size="large" color={COLORS.primary} />
        <Text style={styles.loadingText}>Loading flood data…</Text>
      </View>
    );
  }

  if (!selectedStation) {
    return (
      <View style={styles.centeredContainer}>
        <Ionicons name="water-outline" size={64} color={COLORS.primary} />
        <Text style={styles.promptTitle}>No Station Selected</Text>
        <Text style={styles.promptBody}>
          Select a monitoring station in the Profile tab to see real-time flood data.
        </Text>
      </View>
    );
  }

  const riskLabel: RiskLabel =
    (riskScore?.risk_label as RiskLabel) ??
    (selectedStation.risk_label as RiskLabel) ??
    'Safe';
  const config = riskConfig[riskLabel] ?? riskConfig.Safe;

  const updatedAt = selectedStation.timestamp
    ? new Date(selectedStation.timestamp).toLocaleString()
    : 'Unknown';

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Risk Banner */}
      <View style={[styles.riskBanner, { backgroundColor: config.bg, minHeight: BANNER_HEIGHT }]}>
        <Ionicons name={config.icon as any} size={48} color="#FFFFFF" />
        <Text style={styles.riskLabel}>{riskLabel.toUpperCase()}</Text>
        {riskScore && (
          <Text style={styles.riskScore}>
            Risk Score: {(riskScore.risk_score * 100).toFixed(0)}%
          </Text>
        )}
      </View>

      {/* Hero Stats */}
      <View style={styles.heroCard}>
        <Text style={styles.stationTitle}>{selectedStation.station_name}</Text>
        <Text style={styles.riverSubtitle}>{selectedStation.river_name}</Text>

        <View style={styles.statsRow}>
          <View style={styles.statBlock}>
            <Text style={styles.statValue}>{selectedStation.water_level_m.toFixed(2)}</Text>
            <Text style={styles.statUnit}>metres</Text>
            <Text style={styles.statLabel}>Water Level</Text>
          </View>
          <View style={styles.divider} />
          <View style={styles.statBlock}>
            <Text style={styles.statValue}>{selectedStation.rainfall_mm3.toFixed(1)}</Text>
            <Text style={styles.statUnit}>mm³</Text>
            <Text style={styles.statLabel}>Rainfall</Text>
          </View>
        </View>
      </View>

      {/* Footer */}
      <View style={styles.footer}>
        <Text style={styles.updatedText}>Last updated: {updatedAt}</Text>
        {error && <Text style={styles.errorText}>{error}</Text>}
        <TouchableOpacity style={styles.refreshBtn} onPress={refresh}>
          <Ionicons name="refresh" size={20} color="#FFFFFF" />
          <Text style={styles.refreshText}>Refresh</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  content: { paddingBottom: SPACING.xl },
  centeredContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: SPACING.xl,
    backgroundColor: COLORS.background,
  },
  loadingText: {
    marginTop: SPACING.md,
    fontSize: FONTS.subtitle,
    color: COLORS.textSecondary,
  },
  promptTitle: {
    fontSize: FONTS.title,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: SPACING.lg,
    textAlign: 'center',
  },
  promptBody: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    textAlign: 'center',
    marginTop: SPACING.sm,
    lineHeight: 24,
  },
  riskBanner: {
    justifyContent: 'center',
    alignItems: 'center',
    paddingVertical: SPACING.xl,
    paddingHorizontal: SPACING.lg,
  },
  riskLabel: {
    fontSize: 40,
    fontWeight: '900',
    color: '#FFFFFF',
    marginTop: SPACING.sm,
    letterSpacing: 3,
  },
  riskScore: {
    fontSize: FONTS.subtitle,
    color: 'rgba(255,255,255,0.85)',
    marginTop: SPACING.xs,
  },
  heroCard: {
    margin: SPACING.md,
    backgroundColor: COLORS.surface,
    borderRadius: 16,
    padding: SPACING.lg,
  },
  stationTitle: {
    fontSize: FONTS.title,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginBottom: SPACING.xs,
  },
  riverSubtitle: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginBottom: SPACING.lg,
  },
  statsRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statBlock: {
    flex: 1,
    alignItems: 'center',
  },
  statValue: {
    fontSize: FONTS.hero,
    fontWeight: '800',
    color: COLORS.primaryDark,
  },
  statUnit: {
    fontSize: FONTS.small,
    color: COLORS.textSecondary,
  },
  statLabel: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginTop: SPACING.xs,
  },
  divider: {
    width: 1,
    height: 60,
    backgroundColor: COLORS.textSecondary,
    opacity: 0.2,
  },
  footer: {
    padding: SPACING.md,
    alignItems: 'center',
  },
  updatedText: {
    fontSize: FONTS.small,
    color: COLORS.textSecondary,
    marginBottom: SPACING.md,
  },
  errorText: {
    fontSize: FONTS.body,
    color: COLORS.danger,
    marginBottom: SPACING.sm,
  },
  refreshBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.primary,
    paddingVertical: SPACING.sm,
    paddingHorizontal: SPACING.lg,
    borderRadius: 10,
    gap: SPACING.xs,
  },
  refreshText: {
    fontSize: FONTS.subtitle,
    color: '#FFFFFF',
    fontWeight: '600',
    marginLeft: SPACING.xs,
  },
});
