import React, { useEffect, useState, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  FlatList,
  Alert,
  Animated,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useUserProfile } from '../hooks/useUserProfile';
import { fetchStations } from '../services/apiService';
import { getCurrentLocation } from '../services/locationService';
import { StationReading } from '../types';
import { COLORS, FONTS, SPACING } from '../constants/theme';

export default function ProfileScreen() {
  const { profile, loading, saving, loadProfile, saveProfile, updateSelectedStation, addAlertArea, removeAlertArea } =
    useUserProfile();

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [stations, setStations] = useState<StationReading[]>([]);
  const [toastVisible, setToastVisible] = useState(false);
  const toastOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    loadProfile();
    fetchStations().then((data) => { if (data) setStations(data); });
  }, []);

  useEffect(() => {
    if (profile) {
      setName(profile.name ?? '');
      setEmail(profile.email ?? '');
      setAddress(profile.home_address ?? '');
    }
  }, [profile]);

  const showToast = () => {
    setToastVisible(true);
    Animated.sequence([
      Animated.timing(toastOpacity, { toValue: 1, duration: 300, useNativeDriver: true }),
      Animated.delay(2000),
      Animated.timing(toastOpacity, { toValue: 0, duration: 300, useNativeDriver: true }),
    ]).start(() => setToastVisible(false));
  };

  const handleSave = async () => {
    await saveProfile({ name, email, home_address: address });
    showToast();
  };

  const handleAddCurrentLocationAsAlertZone = async () => {
    try {
      const loc = await getCurrentLocation();
      const areaId = `area_${Date.now()}`;
      await addAlertArea(areaId);
      Alert.alert('Alert Zone Added', `Zone added at ${loc.lat.toFixed(4)}, ${loc.lng.toFixed(4)}`);
    } catch (e) {
      Alert.alert('Error', 'Could not get current location.');
    }
  };

  if (loading) {
    return (
      <View style={styles.centeredContainer}>
        <Text style={styles.loadingText}>Loading profile…</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionTitle}>Personal Info</Text>

      <Text style={styles.label}>Full Name</Text>
      <TextInput
        style={styles.input}
        value={name}
        onChangeText={setName}
        placeholder="Enter your full name"
        placeholderTextColor={COLORS.textSecondary}
      />

      <Text style={styles.label}>Email</Text>
      <TextInput
        style={styles.input}
        value={email}
        onChangeText={setEmail}
        placeholder="Enter your email"
        placeholderTextColor={COLORS.textSecondary}
        keyboardType="email-address"
        autoCapitalize="none"
      />

      <Text style={styles.label}>Home Address</Text>
      <TextInput
        style={[styles.input, styles.multiline]}
        value={address}
        onChangeText={setAddress}
        placeholder="Enter your home address"
        placeholderTextColor={COLORS.textSecondary}
        multiline
        numberOfLines={3}
      />

      {/* Station Selector */}
      <Text style={styles.sectionTitle}>Monitoring Station</Text>
      <Text style={styles.hint}>Tap a station to monitor it on the Home screen.</Text>

      {stations.map((station) => {
        const isSelected = profile?.selected_station_id === station.station_id;
        return (
          <TouchableOpacity
            key={station.station_id}
            style={[styles.stationItem, isSelected && styles.stationItemSelected]}
            onPress={() => updateSelectedStation(station.station_id)}
          >
            <Text style={[styles.stationItemText, isSelected && styles.stationItemTextSelected]}>
              {station.station_name}
            </Text>
            <Text style={[styles.stationSubtext, isSelected && { color: '#FFFFFF' }]}>
              {station.river_name}
            </Text>
            {isSelected && (
              <Ionicons name="checkmark-circle" size={20} color="#FFFFFF" style={styles.checkIcon} />
            )}
          </TouchableOpacity>
        );
      })}

      {/* Alert Areas */}
      <Text style={styles.sectionTitle}>Alert Zones</Text>
      {(profile?.alert_areas ?? []).length === 0 ? (
        <Text style={styles.hint}>No alert zones added yet.</Text>
      ) : (
        (profile?.alert_areas ?? []).map((areaId) => (
          <View key={areaId} style={styles.alertRow}>
            <Text style={styles.alertText}>{areaId}</Text>
            <TouchableOpacity onPress={() => removeAlertArea(areaId)}>
              <Ionicons name="trash-outline" size={22} color={COLORS.danger} />
            </TouchableOpacity>
          </View>
        ))
      )}

      <TouchableOpacity style={styles.addZoneBtn} onPress={handleAddCurrentLocationAsAlertZone}>
        <Ionicons name="location" size={20} color={COLORS.primary} />
        <Text style={styles.addZoneText}>Add Current Location as Alert Zone</Text>
      </TouchableOpacity>

      {/* Save Button */}
      <TouchableOpacity style={styles.saveBtn} onPress={handleSave} disabled={saving}>
        <Text style={styles.saveBtnText}>{saving ? 'Saving…' : 'Save Profile'}</Text>
      </TouchableOpacity>

      {/* Toast */}
      {toastVisible && (
        <Animated.View style={[styles.toast, { opacity: toastOpacity }]}>
          <Ionicons name="checkmark-circle" size={20} color="#FFFFFF" />
          <Text style={styles.toastText}>Profile saved!</Text>
        </Animated.View>
      )}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: COLORS.background },
  content: { padding: SPACING.md, paddingBottom: SPACING.xxl },
  centeredContainer: { flex: 1, justifyContent: 'center', alignItems: 'center' },
  loadingText: { fontSize: FONTS.subtitle, color: COLORS.textSecondary },
  sectionTitle: {
    fontSize: FONTS.title,
    fontWeight: '700',
    color: COLORS.textPrimary,
    marginTop: SPACING.lg,
    marginBottom: SPACING.sm,
  },
  label: {
    fontSize: FONTS.body,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginBottom: SPACING.xs,
    marginTop: SPACING.sm,
  },
  input: {
    backgroundColor: COLORS.surface,
    borderRadius: 10,
    padding: SPACING.md,
    fontSize: FONTS.subtitle,
    color: COLORS.textPrimary,
    borderWidth: 1,
    borderColor: 'transparent',
  },
  multiline: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  hint: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginBottom: SPACING.sm,
  },
  stationItem: {
    backgroundColor: COLORS.surface,
    borderRadius: 10,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
    flexDirection: 'row',
    alignItems: 'center',
  },
  stationItemSelected: {
    backgroundColor: COLORS.primary,
  },
  stationItemText: {
    fontSize: FONTS.subtitle,
    fontWeight: '600',
    color: COLORS.textPrimary,
    flex: 1,
  },
  stationItemTextSelected: {
    color: '#FFFFFF',
  },
  stationSubtext: {
    fontSize: FONTS.body,
    color: COLORS.textSecondary,
    marginLeft: SPACING.sm,
  },
  checkIcon: { marginLeft: SPACING.sm },
  alertRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: COLORS.surface,
    borderRadius: 10,
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  alertText: { flex: 1, fontSize: FONTS.body, color: COLORS.textPrimary },
  addZoneBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: SPACING.md,
    borderRadius: 10,
    borderWidth: 1.5,
    borderColor: COLORS.primary,
    marginBottom: SPACING.lg,
    gap: SPACING.sm,
  },
  addZoneText: {
    fontSize: FONTS.body,
    color: COLORS.primary,
    fontWeight: '600',
    marginLeft: SPACING.sm,
  },
  saveBtn: {
    backgroundColor: COLORS.primary,
    borderRadius: 12,
    padding: SPACING.md,
    alignItems: 'center',
  },
  saveBtnText: { fontSize: FONTS.subtitle, fontWeight: '700', color: '#FFFFFF' },
  toast: {
    position: 'absolute',
    bottom: 90,
    left: SPACING.md,
    right: SPACING.md,
    backgroundColor: COLORS.safe,
    borderRadius: 10,
    padding: SPACING.md,
    flexDirection: 'row',
    alignItems: 'center',
    gap: SPACING.sm,
  },
  toastText: { fontSize: FONTS.body, color: '#FFFFFF', fontWeight: '600', marginLeft: SPACING.sm },
});
