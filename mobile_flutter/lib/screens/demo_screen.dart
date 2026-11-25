import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flood_level.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widgets.dart';

/// Controls for showing off the alert flow in a presentation.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key, required this.initialStationId});
  final String initialStationId;

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  late String _stationId = widget.initialStationId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;
    final st = app.stationById(_stationId);
    final text = Theme.of(context).textTheme;
    final running = app.scenarioRunning && app.scenarioStationId == st.id;
    final minV = (st.normalLevel - 1.0).clamp(-2.0, st.realLevel - 0.2).toDouble();
    final maxV = st.dangerLevel + 1.0;

    return Scaffold(
      appBar: AppBar(title: Text(s.demoTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          // Station picker
          Text(s.demoStation, style: text.titleMedium),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _stationId,
            isExpanded: true,
            itemHeight: 64,
            style: const TextStyle(fontSize: 18, color: AppTheme.ink, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: [
              for (final x in app.stations)
                DropdownMenuItem(value: x.id, child: Text(x.name, overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => _stationId = v);
              if (app.pretendAtStationId != null) app.setPretendAtStation(v);
            },
          ),
          const SizedBox(height: 16),

          // Current state
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [
                  LevelChip(level: st.level, s: s, large: true),
                  const Spacer(),
                  Text(fmtMetres(st.currentLevel),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                ]),
                const SizedBox(height: 12),
                LevelGauge(station: st, s: s),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${s.realReading}: ${fmtMetres(st.realLevel)} (${fmtDateTime(st.realReadingTime)})',
                      style: text.bodySmall),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Quick jump buttons
          Text(s.setLevel, style: text.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.3,
            children: [
              for (final l in FloodLevel.values)
                _LevelButton(
                  level: l,
                  label: s.levelName(l),
                  value: l == FloodLevel.normal ? fmtMetres(st.realLevel) : '≥ ${fmtMetres(st.thresholdFor(l))}',
                  active: st.level == l,
                  onTap: running ? null : () => app.jumpTo(st.id, l),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Slider
          Text(s.slideLevel, style: text.titleMedium),
          Slider(
            value: st.currentLevel.clamp(minV, maxV),
            min: minV,
            max: maxV,
            divisions: ((maxV - minV) / 0.05).round(),
            label: fmtMetres(st.currentLevel),
            onChanged: running ? null : (v) => app.setLevel(st.id, v),
          ),
          const SizedBox(height: 8),

          // Scenario
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.playHint, style: text.bodyMedium),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: running
                      ? FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF424242)),
                          onPressed: app.stopScenario,
                          icon: const Icon(Icons.stop_rounded, size: 28),
                          label: Text(s.stopScenario),
                        )
                      : FilledButton.icon(
                          onPressed: () => app.playScenario(st.id),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(s.playScenario),
                        ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Pretend location
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              title: Text(s.pretendHere, style: text.titleMedium),
              subtitle: Text(s.pretendHereHint, style: text.bodyMedium),
              value: app.pretendAtStationId == st.id,
              onChanged: (v) => app.setPretendAtStation(v ? st.id : null),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: app.resetAll,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(s.resetAll),
          ),
        ],
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.level,
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });
  final FloodLevel level;
  final String label;
  final String value;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final st = LevelStyle.of(level);
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: onTap == null ? st.background.withValues(alpha: 0.4) : st.background,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: active
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.ink, width: 4),
                  )
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(children: [
              Icon(st.icon, color: st.foreground, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: st.foreground, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text(value,
                      maxLines: 1,
                      style: TextStyle(color: st.foreground, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
