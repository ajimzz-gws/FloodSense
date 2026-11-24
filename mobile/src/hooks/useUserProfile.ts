import { useState, useCallback } from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { UserProfile } from '../types';

const STORAGE_KEY = '@floodsense_user_profile';

export function useUserProfile() {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState<boolean>(false);
  const [saving, setSaving] = useState<boolean>(false);

  const loadProfile = useCallback(async () => {
    setLoading(true);
    try {
      const json = await AsyncStorage.getItem(STORAGE_KEY);
      if (json) {
        setProfile(JSON.parse(json));
      } else {
        // Default empty profile
        const defaultProfile: UserProfile = {
          id: `user_${Date.now()}`,
          name: '',
          email: '',
          home_address: '',
          selected_station_id: '',
          alert_areas: [],
          push_token: null,
          last_known_lat: null,
          last_known_lng: null,
        };
        setProfile(defaultProfile);
        await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(defaultProfile));
      }
    } catch (err) {
      console.warn('[useUserProfile] loadProfile error:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  const saveProfile = useCallback(async (partial: Partial<UserProfile>) => {
    setSaving(true);
    try {
      setProfile((prev) => {
        if (!prev) return prev;
        const updated = { ...prev, ...partial };
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    } catch (err) {
      console.warn('[useUserProfile] saveProfile error:', err);
    } finally {
      setSaving(false);
    }
  }, []);

  const updateSelectedStation = useCallback(
    async (id: string) => {
      await saveProfile({ selected_station_id: id });
    },
    [saveProfile]
  );

  const addAlertArea = useCallback(
    async (areaId: string) => {
      setProfile((prev) => {
        if (!prev) return prev;
        if (prev.alert_areas.includes(areaId)) return prev;
        const updated = { ...prev, alert_areas: [...prev.alert_areas, areaId] };
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const removeAlertArea = useCallback(
    async (areaId: string) => {
      setProfile((prev) => {
        if (!prev) return prev;
        const updated = { ...prev, alert_areas: prev.alert_areas.filter((a) => a !== areaId) };
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  return { profile, loading, saving, loadProfile, saveProfile, updateSelectedStation, addAlertArea, removeAlertArea };
}
