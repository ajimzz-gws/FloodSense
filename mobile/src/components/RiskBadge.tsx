import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { COLORS, FONTS, SPACING } from '../constants/theme';

type RiskLabel = 'Safe' | 'Warning' | 'Danger';

interface RiskBadgeProps {
  riskLabel: RiskLabel;
}

const badgeConfig: Record<RiskLabel, { bg: string; text: string }> = {
  Safe: { bg: COLORS.safe, text: '#FFFFFF' },
  Warning: { bg: COLORS.warning, text: '#FFFFFF' },
  Danger: { bg: COLORS.danger, text: '#FFFFFF' },
};

export default function RiskBadge({ riskLabel }: RiskBadgeProps) {
  const config = badgeConfig[riskLabel] ?? badgeConfig.Safe;
  return (
    <View style={[styles.badge, { backgroundColor: config.bg }]}>
      <Text style={[styles.label, { color: config.text }]}>{riskLabel.toUpperCase()}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: SPACING.md,
    paddingVertical: SPACING.xs,
    borderRadius: 20,
    alignSelf: 'flex-start',
  },
  label: {
    fontSize: FONTS.body,
    fontWeight: '700',
    letterSpacing: 1,
  },
});
