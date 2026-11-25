import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/weather.dart';

/// Result of loading a forecast: the days, when MET data was fetched,
/// and whether it came from the offline cache.
class ForecastResult {
  const ForecastResult(this.days, this.fetchedAt, {this.fromCache = false});
  final List<ForecastDay> days;
  final DateTime fetchedAt;
  final bool fromCache;
}

/// 7-day general forecast from MET Malaysia, published on the
/// Malaysian government open data API (no key needed):
/// https://developer.data.gov.my/realtime-api/weather
class WeatherService {
  WeatherService(this._prefs, {http.Client? client}) : _client = client ?? http.Client();

  final SharedPreferences _prefs;
  final http.Client _client;

  static const _base = 'https://api.data.gov.my/weather/forecast/';

  /// Load the forecast for a MET location ID (e.g. "Ds048" = Kuala Terengganu
  /// district). Falls back to the last saved forecast if offline.
  Future<ForecastResult> fetch(String locationId) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'filter': '$locationId@location__location_id',
      'sort': 'date',
    });
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final days = _parse(res.body);
      if (days.isEmpty) throw Exception('No forecast for $locationId');
      final now = DateTime.now();
      await _prefs.setString('wx_$locationId', res.body);
      await _prefs.setString('wx_${locationId}_at', now.toIso8601String());
      return ForecastResult(days, now);
    } catch (_) {
      final cached = _prefs.getString('wx_$locationId');
      final at = _prefs.getString('wx_${locationId}_at');
      if (cached != null && at != null) {
        final days = _parse(cached);
        if (days.isNotEmpty) {
          return ForecastResult(days, DateTime.parse(at), fromCache: true);
        }
      }
      rethrow;
    }
  }

  /// Parse, sort by date, and drop days that are already over.
  static List<ForecastDay> _parse(String body) {
    final list = (jsonDecode(body) as List).cast<Map<String, dynamic>>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = list.map(ForecastDay.fromJson).where((d) => !d.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return days;
  }
}
