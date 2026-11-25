import 'package:flutter/material.dart';

/// One day of the MET Malaysia general forecast (via api.data.gov.my).
///
/// MET publishes the text in Malay, e.g. "Ribut petir di beberapa tempat".
/// We keep the original and translate it for English users.
class ForecastDay {
  const ForecastDay({
    required this.date,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.summary,
    required this.summaryWhen,
    required this.minTemp,
    required this.maxTemp,
  });

  final DateTime date;
  final String morning;
  final String afternoon;
  final String night;
  final String summary;
  final String summaryWhen;
  final int minTemp;
  final int maxTemp;

  factory ForecastDay.fromJson(Map<String, dynamic> j) => ForecastDay(
        date: DateTime.parse(j['date'] as String),
        morning: (j['morning_forecast'] ?? '') as String,
        afternoon: (j['afternoon_forecast'] ?? '') as String,
        night: (j['night_forecast'] ?? '') as String,
        summary: (j['summary_forecast'] ?? '') as String,
        summaryWhen: (j['summary_when'] ?? '') as String,
        minTemp: (j['min_temp'] as num).round(),
        maxTemp: (j['max_temp'] as num).round(),
      );

  /// Rain severity for the whole day, judged from all its periods.
  RainSeverity get severity => [morning, afternoon, night, summary]
      .map(rainSeverityOf)
      .reduce((a, b) => a.index >= b.index ? a : b);
}

enum RainSeverity { none, light, heavy }

/// How much this forecast phrase matters for flooding.
/// Thunderstorms, "most places" and "widespread" count as heavy.
RainSeverity rainSeverityOf(String ms) {
  final t = ms.toLowerCase();
  if (t.isEmpty || t.contains('tiada hujan')) return RainSeverity.none;
  if (t.contains('ribut petir') || t.contains('menyeluruh') || t.contains('kebanyakan')) {
    return RainSeverity.heavy;
  }
  if (t.contains('hujan')) return RainSeverity.light;
  return RainSeverity.none;
}

IconData weatherIconOf(String ms) {
  final t = ms.toLowerCase();
  if (t.contains('ribut petir')) return Icons.thunderstorm_rounded;
  if (t.contains('tiada hujan')) return Icons.wb_sunny_rounded;
  if (t.contains('hujan')) return Icons.umbrella_rounded;
  if (t.contains('jerebu')) return Icons.blur_on_rounded;
  if (t.contains('berangin')) return Icons.air_rounded;
  return Icons.cloud_rounded;
}

/// Translate a MET Malaysia forecast phrase to English.
///
/// MET phrases are built from three parts, e.g.
/// "Ribut petir" + "di beberapa tempat" + "di kawasan pedalaman"
/// -> "Scattered thunderstorms (inland areas)".
/// Anything unrecognised is returned in the original Malay.
String translateForecast(String ms) {
  var t = ms.trim();
  if (t.isEmpty) return t;
  final lower = t.toLowerCase();
  if (lower == 'tiada hujan') return 'No rain';
  if (lower == 'berjerebu') return 'Hazy';
  if (lower == 'berangin') return 'Windy';

  String? base;
  if (lower.startsWith('ribut petir')) {
    base = 'thunderstorms';
  } else if (lower.startsWith('hujan')) {
    base = 'rain';
  }
  if (base == null) return ms;

  String? area;
  if (lower.contains('kawasan pantai')) area = 'coastal areas';
  if (lower.contains('kawasan pedalaman')) area = 'inland areas';

  String phrase;
  if (lower.contains('satu dua tempat')) {
    phrase = 'Isolated $base';
  } else if (lower.contains('beberapa tempat')) {
    phrase = 'Scattered $base';
  } else if (lower.contains('kebanyakan tempat')) {
    phrase = '${_cap(base)} in most places';
  } else if (lower.contains('menyeluruh')) {
    phrase = 'Widespread $base';
  } else {
    phrase = _cap(base);
  }
  return area == null ? phrase : '$phrase ($area)';
}

/// Translate MET's "summary_when" (e.g. "Pagi dan Petang").
String translateWhen(String ms) {
  const parts = {
    'pagi': 'morning',
    'petang': 'afternoon',
    'malam': 'night',
  };
  final lower = ms.trim().toLowerCase();
  if (lower == 'sepanjang hari') return 'All day';
  if (lower.isEmpty) return '';
  final words = lower.split(' dan ').map((w) => parts[w] ?? w).toList();
  return _cap(words.join(' and '));
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
