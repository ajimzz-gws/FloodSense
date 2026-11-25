import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/flood_level.dart';
import '../models/station.dart';
import '../theme/app_theme.dart';

String fmtMetres(double m) => '${m.toStringAsFixed(2)} m';

String fmtDateTime(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

/// Small pill: icon + level word on the level colour.
class LevelChip extends StatelessWidget {
  const LevelChip({super.key, required this.level, required this.s, this.large = false});
  final FloodLevel level;
  final S s;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final st = LevelStyle.of(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 16 : 12, vertical: large ? 8 : 6),
      decoration: BoxDecoration(color: st.background, borderRadius: BorderRadius.circular(40)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(st.icon, color: st.foreground, size: large ? 24 : 20),
        const SizedBox(width: 6),
        Text(
          s.levelName(level).toUpperCase(),
          style: TextStyle(
            color: st.foreground,
            fontWeight: FontWeight.w800,
            fontSize: large ? 18 : 15,
            letterSpacing: 0.8,
          ),
        ),
      ]),
    );
  }
}

/// Grey outlined tag, e.g. "Sample data".
class InfoTag extends StatelessWidget {
  const InfoTag(this.text, {super.key, this.icon = Icons.info_outline});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.inkSoft),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: AppTheme.inkSoft),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.inkSoft)),
      ]),
    );
  }
}

/// Horizontal bar coloured by the four ranges, with a marker for "now".
class LevelGauge extends StatelessWidget {
  const LevelGauge({super.key, required this.station, required this.s});
  final Station station;
  final S s;

  @override
  Widget build(BuildContext context) {
    final st = station;
    final lo = [st.normalLevel - 0.6, st.currentLevel - 0.3].reduce((a, b) => a < b ? a : b);
    final hi = [st.dangerLevel + 0.4, st.currentLevel + 0.3].reduce((a, b) => a > b ? a : b);
    double frac(double v) => ((v - lo) / (hi - lo)).clamp(0.0, 1.0);

    final segments = <(double, double, FloodLevel)>[
      (lo, st.alertLevel, FloodLevel.normal),
      (st.alertLevel, st.warningLevel, FloodLevel.alert),
      (st.warningLevel, st.dangerLevel, FloodLevel.warning),
      (st.dangerLevel, hi, FloodLevel.danger),
    ];

    return Semantics(
      label: '${s.waterLevel} ${fmtMetres(st.currentLevel)}, ${s.levelName(st.level)}',
      child: ExcludeSemantics(
        child: LayoutBuilder(builder: (context, c) {
          final w = c.maxWidth;
          final x = frac(st.currentLevel) * w;
          final labelW = 92.0;
          final labelLeft = (x - labelW / 2).clamp(0.0, w - labelW);
          return SizedBox(
            height: 78,
            child: Stack(clipBehavior: Clip.none, children: [
              // "NOW" label + arrow
              Positioned(
                left: labelLeft,
                top: 0,
                width: labelW,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fmtMetres(st.currentLevel),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
              Positioned(
                left: x - 12,
                top: 24,
                child: const Icon(Icons.arrow_drop_down, size: 24, color: AppTheme.ink),
              ),
              // Coloured bar
              Positioned(
                left: 0,
                right: 0,
                top: 44,
                height: 26,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Row(children: [
                    for (final (a, b, l) in segments)
                      Expanded(
                        flex: ((frac(b) - frac(a)) * 1000).round().clamp(1, 1000),
                        child: Container(color: LevelStyle.of(l).background),
                      ),
                  ]),
                ),
              ),
              // Current-level line through the bar
              Positioned(
                left: x - 2,
                top: 40,
                width: 4,
                height: 34,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }
}

/// Table of thresholds, highest first, with the current row highlighted.
class ThresholdTable extends StatelessWidget {
  const ThresholdTable({super.key, required this.station, required this.s});
  final Station station;
  final S s;

  @override
  Widget build(BuildContext context) {
    final current = station.level;
    return Column(children: [
      for (final l in FloodLevel.values.reversed)
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: l == current ? LevelStyle.of(l).background.withValues(alpha: 0.18) : null,
            border: Border.all(
              color: l == current ? LevelStyle.of(l).background : const Color(0xFFDCE3EA),
              width: l == current ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: LevelStyle.of(l).background, shape: BoxShape.circle),
              child: Icon(LevelStyle.of(l).icon, color: LevelStyle.of(l).foreground, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.levelName(l), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                if (l == FloodLevel.normal)
                  Text(s.usualLevel(fmtMetres(station.normalLevel)),
                      style: const TextStyle(fontSize: 14, color: AppTheme.inkSoft)),
              ]),
            ),
            if (l == current)
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(6)),
                child: Text(s.now,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            Text(
              l == FloodLevel.normal
                  ? '< ${fmtMetres(station.alertLevel)}'
                  : '≥ ${fmtMetres(station.thresholdFor(l))}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ]),
        ),
    ]);
  }
}
