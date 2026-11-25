import 'package:latlong2/latlong.dart';

import 'flood_level.dart';

/// A river water-level station and its alert thresholds (in metres),
/// in the same shape InfoBanjir publishes them.
class Station {
  Station({
    required this.id,
    required this.name,
    required this.district,
    required this.river,
    required this.basin,
    required this.location,
    required this.normalLevel,
    required this.alertLevel,
    required this.warningLevel,
    required this.dangerLevel,
    required this.realLevel,
    required this.realReadingTime,
    required this.metLocationId,
    this.zoneRadiusKm = 5.0,
    this.isSample = false,
  })  : currentLevel = realLevel,
        updatedAt = realReadingTime;

  final String id;
  final String name;
  final String district;
  final String river;
  final String basin;
  final LatLng location;

  /// Thresholds in metres.
  final double normalLevel;
  final double alertLevel;
  final double warningLevel;
  final double dangerLevel;

  /// The reading taken from the data source (kept so the demo can reset).
  final double realLevel;
  final DateTime realReadingTime;

  /// MET Malaysia forecast location (district ID, e.g. "Ds048").
  final String metLocationId;

  /// Everyone within this distance of the station is in its impact zone.
  final double zoneRadiusKm;

  /// True for made-up stations that only exist to fill the demo.
  final bool isSample;

  /// Current water level in metres. Changed by the demo controls.
  double currentLevel;
  DateTime updatedAt;

  bool get isDemoValue => currentLevel != realLevel;

  FloodLevel get level => classify(currentLevel);

  /// Map a water level to a status. A level at or above a threshold
  /// takes that status (e.g. exactly 1.80 m is Danger).
  FloodLevel classify(double metres) {
    if (metres >= dangerLevel) return FloodLevel.danger;
    if (metres >= warningLevel) return FloodLevel.warning;
    if (metres >= alertLevel) return FloodLevel.alert;
    return FloodLevel.normal;
  }

  /// The threshold value where [lvl] starts (normal uses the normal level).
  double thresholdFor(FloodLevel lvl) => switch (lvl) {
        FloodLevel.normal => normalLevel,
        FloodLevel.alert => alertLevel,
        FloodLevel.warning => warningLevel,
        FloodLevel.danger => dangerLevel,
      };

  void resetToReal() {
    currentLevel = realLevel;
    updatedAt = realReadingTime;
  }
}
