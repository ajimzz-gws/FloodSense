import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/station.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'level_widgets.dart';

/// MET Malaysia forecast for the district of the user's station.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key, required this.app, required this.station});
  final AppState app;
  final Station station;

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final st = widget.station;
    final s = app.s;
    final result = app.forecastFor(st);
    final loading = app.forecastLoading(st);
    final failed = app.forecastFailed(st);
    final text = Theme.of(context).textTheme;

    Widget body;
    if (result == null && loading) {
      body = Row(children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(width: 14),
        Text(s.weatherLoading, style: text.bodyLarge),
      ]);
    } else if (result == null) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(failed ? s.weatherFailed : s.weatherLoading, style: text.bodyLarge),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => app.loadForecast(force: true),
          icon: const Icon(Icons.refresh_rounded),
          label: Text(s.retry),
        ),
      ]);
    } else {
      body = _Forecast(
        result: result,
        s: s,
        expanded: _expanded,
        onToggle: () => setState(() => _expanded = !_expanded),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.cloud_rounded, size: 26, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(s.weatherTitle, style: text.titleLarge)),
            if (result != null)
              IconButton(
                tooltip: s.retry,
                iconSize: 28,
                onPressed: loading ? null : () => app.loadForecast(force: true),
                icon: loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.refresh_rounded),
              ),
          ]),
          Text(s.metSource(st.district), style: text.bodySmall),
          const SizedBox(height: 12),
          body,
        ]),
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.result, required this.s, required this.expanded, required this.onToggle});
  final ForecastResult result;
  final S s;
  final bool expanded;
  final VoidCallback onToggle;

  String _t(String ms) => s.forecastText(ms, translateForecast);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final days = result.days;
    final today = days.first;
    final rest = days.skip(1).take(expanded ? 6 : 3).toList();
    final heavyToday = today.severity == RainSeverity.heavy;
    final heavySoon = days.skip(1).take(3).any((d) => d.severity == RainSeverity.heavy);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (result.fromCache) ...[
        _Note(
          icon: Icons.cloud_off_rounded,
          color: const Color(0xFFECEFF1),
          text: s.offlineForecast(fmtDateTime(result.fetchedAt)),
        ),
        const SizedBox(height: 10),
      ],

      // ---- Today ----
      Semantics(
        container: true,
        label: '${s.today}. ${_t(today.summary)}. ${today.minTemp} to ${today.maxTemp} °C',
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(weatherIconOf(today.summary), size: 56, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${s.today} · ${s.weekday(today.date)}, ${s.shortDate(today.date)}',
                        style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
                    Text(_t(today.summary), style: text.titleLarge),
                    if (today.summaryWhen.isNotEmpty)
                      Text(s.forecastText(today.summaryWhen, translateWhen), style: text.bodyMedium),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.thermostat_rounded, size: 26, color: AppTheme.ink),
                const SizedBox(width: 4),
                Text('${today.minTemp}° – ${today.maxTemp}°C',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              _PeriodRow(label: s.morning, ms: today.morning, translate: _t),
              _PeriodRow(label: s.afternoon, ms: today.afternoon, translate: _t),
              _PeriodRow(label: s.night, ms: today.night, translate: _t),
            ]),
          ),
        ),
      ),

      // ---- Flood-relevant rain note ----
      if (heavyToday || heavySoon) ...[
        const SizedBox(height: 10),
        _Note(
          icon: Icons.water_drop_rounded,
          color: const Color(0xFFFFF3CD),
          text: heavyToday ? s.rainNoteToday : s.rainNoteSoon,
        ),
      ],

      // ---- Next days ----
      if (rest.isNotEmpty) ...[
        const SizedBox(height: 14),
        Text(s.nextDays, style: text.titleMedium),
        const SizedBox(height: 6),
        for (final d in rest) _DayRow(day: d, s: s, translate: _t),
        if (days.length > 4)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 28),
              label: Text(expanded ? s.showFewerDays : s.showAllDays,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
      const SizedBox(height: 4),
      Text('${s.updated}: ${fmtDateTime(result.fetchedAt)}', style: text.bodySmall),
    ]);
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.label, required this.ms, required this.translate});
  final String label;
  final String ms;
  final String Function(String) translate;

  @override
  Widget build(BuildContext context) {
    if (ms.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
        Icon(weatherIconOf(ms), size: 22, color: AppTheme.primary),
        const SizedBox(width: 6),
        Expanded(child: Text(translate(ms), style: const TextStyle(fontSize: 16))),
      ]),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.s, required this.translate});
  final ForecastDay day;
  final S s;
  final String Function(String) translate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8EE))),
      ),
      child: Row(children: [
        SizedBox(
          width: 82,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.weekday(day.date), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            Text(s.shortDate(day.date), style: const TextStyle(fontSize: 14, color: AppTheme.inkSoft)),
          ]),
        ),
        Icon(weatherIconOf(day.summary), size: 30, color: AppTheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(translate(day.summary), style: const TextStyle(fontSize: 16))),
        const SizedBox(width: 8),
        Text('${day.minTemp}–${day.maxTemp}°',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 26, color: AppTheme.ink),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.35, color: AppTheme.ink))),
      ]),
    );
  }
}
