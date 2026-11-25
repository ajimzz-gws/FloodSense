import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widgets.dart';

class StationsScreen extends StatelessWidget {
  const StationsScreen({super.key, required this.onChosen});
  final VoidCallback onChosen;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(s.stationsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(s.tapToChoose, style: text.bodyLarge!.copyWith(color: AppTheme.inkSoft)),
          const SizedBox(height: 12),
          for (final st in app.stations) ...[
            Builder(builder: (context) {
              final selected = st.id == app.myStation.id;
              final style = LevelStyle.of(st.level);
              final km = app.distanceKm(st);
              return Semantics(
                button: true,
                selected: selected,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: selected ? AppTheme.primary : const Color(0xFFDCE3EA),
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: InkWell(
                    onTap: () {
                      app.setMyStation(st.id);
                      onChosen();
                    },
                    child: IntrinsicHeight(
                      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Container(width: 12, color: style.background),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                LevelChip(level: st.level, s: s),
                                const Spacer(),
                                Text(fmtMetres(st.currentLevel),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                              ]),
                              const SizedBox(height: 10),
                              Text(st.name, style: text.titleLarge),
                              Text(
                                '${st.district} · ${st.river}${km != null ? ' · ${km.toStringAsFixed(1)} km' : ''}',
                                style: text.bodyMedium!.copyWith(color: AppTheme.inkSoft),
                              ),
                              const SizedBox(height: 8),
                              Wrap(spacing: 8, runSpacing: 6, children: [
                                if (selected)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                                      const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 4),
                                      Text(s.selected,
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                    ]),
                                  ),
                                if (st.isSample) InfoTag(s.sampleData),
                                if (st.isDemoValue) InfoTag(s.demoValue, icon: Icons.tune_rounded),
                              ]),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
