import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flood_level.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widgets.dart';
import '../widgets/weather_card.dart';
import 'demo_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onChangeStation});
  final VoidCallback onChangeStation;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;
    final st = app.myStation;
    final level = st.level;
    final style = LevelStyle.of(level);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FloodSense'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => DemoScreen(initialStationId: st.id)),
              ),
              icon: const Icon(Icons.tune_rounded, size: 26),
              label: Text(s.demoMode, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          // ---- Station header ----
          Text(s.myStation.toUpperCase(),
              style: text.bodySmall!.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(st.name, style: text.headlineSmall),
          Text('${st.river} · ${st.district}', style: text.bodyMedium!.copyWith(color: AppTheme.inkSoft)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (st.isSample) InfoTag(s.sampleData),
            if (st.isDemoValue) InfoTag(s.demoValue, icon: Icons.tune_rounded),
          ]),
          const SizedBox(height: 12),

          // ---- Big status card ----
          Semantics(
            container: true,
            label: '${s.levelName(level)}. ${s.waterLevel} ${fmtMetres(st.currentLevel)}',
            child: ExcludeSemantics(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(style.icon, size: 72, color: style.foreground),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.levelName(level).toUpperCase(),
                        style: TextStyle(
                          color: style.foreground,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(height: 2, color: style.foreground.withValues(alpha: 0.35)),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Text(s.waterLevel,
                          style: TextStyle(color: style.foreground, fontSize: 20, fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      fmtMetres(st.currentLevel),
                      style: TextStyle(color: style.foreground, fontSize: 40, fontWeight: FontWeight.w900),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ---- Weather forecast (MET Malaysia) ----
          WeatherCard(app: app, station: st),
          const SizedBox(height: 12),

          // ---- What to do ----
          _Section(
            icon: Icons.directions_run_rounded,
            title: s.whatToDo,
            child: Text(s.levelAdvice(level), style: text.bodyLarge!.copyWith(fontSize: 20)),
          ),
          const SizedBox(height: 12),

          // ---- Gauge + thresholds ----
          _Section(
            icon: Icons.water_rounded,
            title: s.levelsTitle,
            child: Column(children: [
              LevelGauge(station: st, s: s),
              const SizedBox(height: 14),
              ThresholdTable(station: st, s: s),
            ]),
          ),
          const SizedBox(height: 12),

          // ---- Your area ----
          _Section(
            icon: Icons.my_location_rounded,
            title: s.yourArea,
            child: _AreaText(app: app),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: onChangeStation,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(s.changeStation),
          ),
          const SizedBox(height: 16),
          Text('${s.updated}: ${fmtDateTime(st.updatedAt)}', style: text.bodySmall, textAlign: TextAlign.center),
          Text(s.dataSource, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AreaText extends StatelessWidget {
  const _AreaText({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final s = app.s;
    final st = app.myStation;
    final big = Theme.of(context).textTheme.bodyLarge;
    if (app.pretendAtStationId != null) {
      final inZone = app.isInZone(st);
      return Text(
        '${s.pretendingHere}\n${inZone ? s.inZone(app.distanceKm(st)!.toStringAsFixed(1), st.zoneRadiusKm.toStringAsFixed(0)) : s.outZone(app.distanceKm(st)!.toStringAsFixed(1), st.zoneRadiusKm.toStringAsFixed(0))}',
        style: big,
      );
    }
    switch (app.locationStatus) {
      case LocationStatus.off:
      case LocationStatus.denied:
      case LocationStatus.serviceDisabled:
        return Text(s.locationOff, style: big);
      case LocationStatus.waiting:
        return Text(s.locationWaiting, style: big);
      case LocationStatus.on:
        final d = app.distanceKm(st);
        if (d == null) return Text(s.locationWaiting, style: big);
        final km = d.toStringAsFixed(1);
        final r = st.zoneRadiusKm.toStringAsFixed(0);
        final inZone = app.isInZone(st);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(inZone ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 28, color: inZone && st.level >= FloodLevel.alert ? LevelStyle.of(st.level).background : AppTheme.inkSoft),
          const SizedBox(width: 8),
          Expanded(child: Text(inZone ? s.inZone(km, r) : s.outZone(km, r), style: big)),
        ]);
    }
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.child});
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 26, color: AppTheme.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    );
  }
}
