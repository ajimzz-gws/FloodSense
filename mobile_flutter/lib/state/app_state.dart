import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/stations_data.dart';
import '../l10n/strings.dart';
import '../models/flood_level.dart';
import '../models/station.dart';
import '../services/alert_engine.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

/// An alert the UI should show full-screen.
class AlertEvent {
  AlertEvent(this.station, this.level, this.metres);
  final Station station;
  final FloodLevel level;
  final double metres;
}

/// The whole app's state: stations, the user's settings and location,
/// and the alert logic that ties them together.
class AppState extends ChangeNotifier {
  AppState({
    required SharedPreferences prefs,
    required NotificationService notifications,
    required LocationService location,
    required WeatherService weather,
  })  : _prefs = prefs,
        _notifications = notifications,
        _location = location,
        _weather = weather {
    _language = AppLanguage.values[_prefs.getInt('language') ?? 0];
    _textScale = _prefs.getDouble('textScale') ?? 1.0;
    _trackingEnabled = _prefs.getBool('tracking') ?? true;
    _alertMyStation = _prefs.getBool('alertMyStation') ?? true;
    final saved = _prefs.getString('myStation');
    if (saved != null && stations.any((s) => s.id == saved)) _myStationId = saved;
    for (final s in stations) {
      _lastNotified[s.id] = FloodLevel.normal;
    }
  }

  final SharedPreferences _prefs;
  final NotificationService _notifications;
  final LocationService _location;
  final WeatherService _weather;

  final List<Station> stations = buildStations();
  final Map<String, FloodLevel> _lastNotified = {};

  // ---------- Settings ----------
  late AppLanguage _language;
  late double _textScale;
  late bool _trackingEnabled;
  late bool _alertMyStation;
  String _myStationId = '0670341WL';

  AppLanguage get language => _language;
  S get s => S(_language);
  double get textScale => _textScale;
  bool get trackingEnabled => _trackingEnabled;
  bool get alertMyStation => _alertMyStation;
  Station get myStation => stationById(_myStationId);

  Station stationById(String id) => stations.firstWhere((s) => s.id == id);

  void setLanguage(AppLanguage l) {
    _language = l;
    _prefs.setInt('language', l.index);
    notifyListeners();
    if (_trackingEnabled) _startTracking(); // refresh notification text
  }

  void setTextScale(double v) {
    _textScale = v;
    _prefs.setDouble('textScale', v);
    notifyListeners();
  }

  void setMyStation(String id) {
    _myStationId = id;
    _prefs.setString('myStation', id);
    notifyListeners();
    _evaluateAll();
    loadForecast();
  }

  // ---------- Weather (MET Malaysia) ----------
  final Map<String, ForecastResult> _forecasts = {};
  final Set<String> _forecastLoading = {};
  final Set<String> _forecastFailed = {};

  ForecastResult? forecastFor(Station st) => _forecasts[st.metLocationId];
  bool forecastLoading(Station st) => _forecastLoading.contains(st.metLocationId);
  bool forecastFailed(Station st) => _forecastFailed.contains(st.metLocationId);

  /// Fetch the forecast for my station. Re-uses a result less than
  /// 30 minutes old unless [force] is set.
  Future<void> loadForecast({bool force = false}) async {
    final id = myStation.metLocationId;
    final have = _forecasts[id];
    if (_forecastLoading.contains(id)) return;
    if (!force &&
        have != null &&
        !have.fromCache &&
        DateTime.now().difference(have.fetchedAt) < const Duration(minutes: 30)) {
      return;
    }
    _forecastLoading.add(id);
    _forecastFailed.remove(id);
    notifyListeners();
    try {
      _forecasts[id] = await _weather.fetch(id);
    } catch (e) {
      debugPrint('[Weather] $e');
      _forecastFailed.add(id);
    } finally {
      _forecastLoading.remove(id);
      notifyListeners();
    }
  }

  void setAlertMyStation(bool v) {
    _alertMyStation = v;
    _prefs.setBool('alertMyStation', v);
    notifyListeners();
    _evaluateAll();
  }

  // ---------- Location ----------
  LocationStatus _locationStatus = LocationStatus.off;
  LatLng? _realPosition;
  String? _pretendAtStationId; // demo: put the user at a station

  LocationStatus get locationStatus => _locationStatus;
  String? get pretendAtStationId => _pretendAtStationId;

  /// Where the app thinks the user is (demo override wins).
  LatLng? get position => _pretendAtStationId != null
      ? stationById(_pretendAtStationId!).location
      : _realPosition;

  double? distanceKm(Station st) {
    final p = position;
    if (p == null) return null;
    return const Distance().as(LengthUnit.Meter, p, st.location) / 1000.0;
  }

  bool isInZone(Station st) {
    final d = distanceKm(st);
    return d != null && d <= st.zoneRadiusKm;
  }

  /// Who should be alerted for this station: people in its zone, plus
  /// (optionally) anyone who picked it as their station.
  bool isAffected(Station st) =>
      isInZone(st) || (_alertMyStation && st.id == _myStationId);

  Future<void> initPermissionsAndTracking() async {
    loadForecast();
    await _notifications.requestPermission();
    if (_trackingEnabled) await _enableTracking();
    _evaluateAll();
  }

  Future<void> setTrackingEnabled(bool v) async {
    _trackingEnabled = v;
    _prefs.setBool('tracking', v);
    if (v) {
      await _enableTracking();
    } else {
      _location.stop();
      _realPosition = null;
      _locationStatus = LocationStatus.off;
      notifyListeners();
    }
  }

  Future<void> _enableTracking() async {
    _locationStatus = LocationStatus.waiting;
    notifyListeners();
    final status = await _location.requestPermission();
    if (status != LocationStatus.on) {
      _locationStatus = status;
      notifyListeners();
      return;
    }
    _startTracking();
  }

  void _startTracking() {
    if (_locationStatus == LocationStatus.denied ||
        _locationStatus == LocationStatus.serviceDisabled) {
      return;
    }
    _location.start(
      notificationTitle: s.trackingNotifTitle,
      notificationText: s.trackingNotifBody,
      onPosition: (p) {
        _realPosition = p;
        _locationStatus = LocationStatus.on;
        notifyListeners();
        _evaluateAll();
      },
      onError: (e) {
        debugPrint('[Location] $e');
      },
    );
  }

  Future<void> openPhoneSettings() => _location.openPhoneSettings();

  // ---------- Demo controls ----------
  Timer? _scenario;
  String? _scenarioStationId;
  bool get scenarioRunning => _scenario != null;
  String? get scenarioStationId => _scenarioStationId;

  void setLevel(String stationId, double metres) {
    final st = stationById(stationId);
    st.currentLevel = double.parse(metres.toStringAsFixed(2));
    st.updatedAt = DateTime.now();
    notifyListeners();
    _evaluate(st);
  }

  /// Jump to just inside a level (normal = back to the real reading).
  void jumpTo(String stationId, FloodLevel level) {
    final st = stationById(stationId);
    setLevel(stationId, level == FloodLevel.normal ? st.realLevel : st.thresholdFor(level) + 0.05);
  }

  void setPretendAtStation(String? stationId) {
    _pretendAtStationId = stationId;
    notifyListeners();
    _evaluateAll();
  }

  /// Raise the water in steps from its current level to just past Danger.
  void playScenario(String stationId) {
    stopScenario();
    final st = stationById(stationId);
    final target = st.dangerLevel + 0.15;
    if (st.currentLevel >= target) st.resetToReal();
    const steps = 16;
    final step = (target - st.currentLevel) / steps;
    var i = 0;
    _scenarioStationId = stationId;
    _scenario = Timer.periodic(const Duration(milliseconds: 1500), (t) {
      i++;
      setLevel(stationId, st.currentLevel + step);
      if (i >= steps) stopScenario();
    });
    notifyListeners();
  }

  void stopScenario() {
    _scenario?.cancel();
    _scenario = null;
    _scenarioStationId = null;
    notifyListeners();
  }

  void resetAll() {
    stopScenario();
    for (final st in stations) {
      st.resetToReal();
      _lastNotified[st.id] = st.level;
    }
    _pretendAtStationId = null;
    notifyListeners();
  }

  // ---------- Alerts ----------
  AlertEvent? _pendingAlert;
  AlertEvent? get pendingAlert => _pendingAlert;

  /// The UI calls this once it has shown the pending alert.
  AlertEvent? takePendingAlert() {
    final a = _pendingAlert;
    _pendingAlert = null;
    return a;
  }

  void _evaluateAll() {
    for (final st in stations) {
      _evaluate(st);
    }
  }

  void _evaluate(Station st) {
    final decision = AlertEngine.decide(
      current: st.level,
      lastNotified: _lastNotified[st.id]!,
      inZone: isAffected(st),
    );
    _lastNotified[st.id] = decision.lastNotified;
    if (decision.notify) _fireAlert(st);
  }

  void _fireAlert(Station st) {
    final lvl = st.level;
    final metres = st.currentLevel.toStringAsFixed(2);
    _notifications.showFloodAlert(
      id: st.id.hashCode & 0x7fffffff,
      title: '${s.alertTitle(lvl)} · ${st.name}',
      body: '${s.alertBody(st.name, s.levelName(lvl), metres)}\n${s.levelAdvice(lvl)}',
      color: LevelStyle.of(lvl).background,
    );
    _pendingAlert = AlertEvent(st, lvl, st.currentLevel);
    notifyListeners();
  }

  @override
  void dispose() {
    _scenario?.cancel();
    _location.stop();
    super.dispose();
  }
}
