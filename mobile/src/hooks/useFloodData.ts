import { useState, useEffect, useRef, useCallback } from 'react';
import { StationReading, FloodRiskScore } from '../types';
import { fetchStations, fetchStationHistory, submitPredictionRequest } from '../services/apiService';

const POLL_INTERVAL_MS = 60_000;

export function useFloodData() {
  const [stations, setStations] = useState<StationReading[]>([]);
  const [selectedStation, setSelectedStation] = useState<StationReading | null>(null);
  const [riskScore, setRiskScore] = useState<FloodRiskScore | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const loadStations = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fetchStations();
      if (data) {
        setStations(data);
      } else {
        setError('Failed to load stations.');
      }
    } catch (e) {
      setError('Unexpected error loading stations.');
    } finally {
      setLoading(false);
    }
  }, []);

  const pollSelectedStation = useCallback(async (stationId: string) => {
    try {
      const history = await fetchStationHistory(stationId);
      if (history && history.length > 0) {
        const waterHistory = history.map((r) => r.water_level_m);
        const rainHistory = history.map((r) => r.rainfall_mm3);
        const risk = await submitPredictionRequest({
          station_id: stationId,
          water_level_history: waterHistory,
          rainfall_history: rainHistory,
        });
        if (risk) setRiskScore(risk);
      }
    } catch (e) {
      console.warn('[useFloodData] Poll error:', e);
    }
  }, []);

  const selectStation = useCallback(
    (id: string) => {
      const station = stations.find((s) => s.station_id === id) ?? null;
      setSelectedStation(station);
      setRiskScore(null);
      if (station) pollSelectedStation(id);
    },
    [stations, pollSelectedStation]
  );

  const refresh = useCallback(async () => {
    await loadStations();
    if (selectedStation) {
      await pollSelectedStation(selectedStation.station_id);
    }
  }, [loadStations, selectedStation, pollSelectedStation]);

  useEffect(() => {
    loadStations();
  }, [loadStations]);

  useEffect(() => {
    if (!selectedStation) return;
    intervalRef.current = setInterval(() => {
      pollSelectedStation(selectedStation.station_id);
    }, POLL_INTERVAL_MS);
    return () => {
      if (intervalRef.current) clearInterval(intervalRef.current);
    };
  }, [selectedStation, pollSelectedStation]);

  return { stations, selectedStation, riskScore, loading, error, selectStation, refresh };
}
