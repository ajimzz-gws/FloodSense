import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/flood_level.dart';
import '../models/station.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widgets.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.onChosen});
  final VoidCallback onChosen;

  static const _terengganu = LatLng(5.0, 103.0);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;
    final pos = app.position;

    return Scaffold(
      appBar: AppBar(title: Text(s.mapTitle)),
      body: Stack(children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: _terengganu,
            initialZoom: 8,
            interactionOptions: InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.floodsense.floodsense',
            ),
            CircleLayer(circles: [
              for (final st in app.stations)
                CircleMarker(
                  point: st.location,
                  radius: st.zoneRadiusKm * 1000,
                  useRadiusInMeter: true,
                  color: LevelStyle.of(st.level).background.withValues(alpha: 0.22),
                  borderColor: LevelStyle.of(st.level).background,
                  borderStrokeWidth: 2,
                ),
            ]),
            MarkerLayer(markers: [
              for (final st in app.stations)
                Marker(
                  point: st.location,
                  width: 60,
                  height: 60,
                  child: Semantics(
                    button: true,
                    label: '${st.name}, ${s.levelName(st.level)}, ${fmtMetres(st.currentLevel)}',
                    child: GestureDetector(
                      onTap: () => _showStation(context, app, st),
                      child: _StationPin(level: st.level, selected: st.id == app.myStation.id),
                    ),
                  ),
                ),
              if (pos != null)
                Marker(
                  point: pos,
                  width: 64,
                  height: 64,
                  child: Semantics(label: s.you, child: _UserPin(label: s.you)),
                ),
            ]),
            const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
          ],
        ),
        Positioned(left: 12, top: 12, child: _Legend(app: app)),
      ]),
    );
  }

  void _showStation(BuildContext context, AppState app, Station st) {
    final s = app.s;
    final km = app.distanceKm(st);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              LevelChip(level: st.level, s: s, large: true),
              const Spacer(),
              Text(fmtMetres(st.currentLevel), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            Text(st.name, style: Theme.of(ctx).textTheme.headlineSmall),
            Text(
              '${st.district} · ${st.river}${km != null ? ' · ${km.toStringAsFixed(1)} km' : ''}',
              style: Theme.of(ctx).textTheme.bodyLarge!.copyWith(color: AppTheme.inkSoft),
            ),
            if (st.isSample) ...[const SizedBox(height: 8), InfoTag(s.sampleData)],
            const SizedBox(height: 12),
            Text(s.levelAdvice(st.level), style: Theme.of(ctx).textTheme.bodyLarge),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  app.setMyStation(st.id);
                  Navigator.of(ctx).pop();
                  onChosen();
                },
                icon: const Icon(Icons.check_rounded),
                label: Text(s.setAsMyStation),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StationPin extends StatelessWidget {
  const _StationPin({required this.level, required this.selected});
  final FloodLevel level;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final st = LevelStyle.of(level);
    return Container(
      decoration: BoxDecoration(
        color: st.background,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? AppTheme.ink : Colors.white, width: selected ? 5 : 3),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38, offset: Offset(0, 2))],
      ),
      child: Icon(st.icon, color: st.foreground, size: 30),
    );
  }
}

class _UserPin extends StatelessWidget {
  const _UserPin({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(color: AppTheme.ink, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ),
      const SizedBox(height: 2),
      Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF2979FF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black38)],
        ),
      ),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.app});
  final AppState app;

  @override
  Widget build(BuildContext context) {
    final s = app.s;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          for (final l in FloodLevel.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: LevelStyle.of(l).background, shape: BoxShape.circle),
                  child: Icon(LevelStyle.of(l).icon, size: 16, color: LevelStyle.of(l).foreground),
                ),
                const SizedBox(width: 8),
                Text(s.levelName(l), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
            ),
          const SizedBox(height: 4),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 26,
              height: 14,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.inkSoft, width: 2),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(width: 8),
            Text('${s.alertZone} (5 km)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}
