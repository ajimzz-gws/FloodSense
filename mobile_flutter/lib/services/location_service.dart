import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus { off, waiting, on, denied, serviceDisabled }

/// Continuous location tracking.
///
/// On Android this runs as a foreground service (with a permanent
/// notification), so it keeps working while the app is in the background.
class LocationService {
  StreamSubscription<Position>? _sub;

  /// Ask for permission. Returns the resulting status.
  Future<LocationStatus> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationStatus.serviceDisabled;
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return LocationStatus.denied;
    }
    // "While using the app" is enough: tracking runs as a foreground
    // service (with a permanent notification), so it continues in the
    // background without needing "Allow all the time".
    return LocationStatus.on;
  }

  void start({
    required String notificationTitle,
    required String notificationText,
    required void Function(LatLng) onPosition,
    required void Function(Object) onError,
  }) {
    stop();
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 25, // metres moved before an update
      intervalDuration: const Duration(seconds: 15),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        notificationChannelName: 'Location tracking',
        notificationIcon: const AndroidResource(name: 'ic_stat_flood', defType: 'drawable'),
        enableWakeLock: true,
        setOngoing: true,
        color: const Color(0xFF0D47A1),
      ),
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) => onPosition(LatLng(p.latitude, p.longitude)),
      onError: onError,
    );
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  Future<void> openPhoneSettings() => Geolocator.openAppSettings();
}
