import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/location_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'demo_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.s;
    final text = Theme.of(context).textTheme;
    final denied = app.trackingEnabled &&
        (app.locationStatus == LocationStatus.denied ||
            app.locationStatus == LocationStatus.serviceDisabled);

    return Scaffold(
      appBar: AppBar(title: Text(s.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _Card(
            icon: Icons.translate_rounded,
            title: s.language,
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppLanguage>(
                showSelectedIcon: true,
                style: _segStyle,
                segments: const [
                  ButtonSegment(value: AppLanguage.en, label: Text('English')),
                  ButtonSegment(value: AppLanguage.ms, label: Text('Bahasa Melayu')),
                ],
                selected: {app.language},
                onSelectionChanged: (v) => app.setLanguage(v.first),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.format_size_rounded,
            title: s.textSize,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<double>(
                  showSelectedIcon: false,
                  style: _segStyle,
                  segments: [
                    ButtonSegment(value: 1.0, label: Text(s.sizeNormal)),
                    ButtonSegment(value: 1.2, label: Text(s.sizeLarge)),
                    ButtonSegment(value: 1.4, label: Text(s.sizeXL)),
                  ],
                  selected: {app.textScale},
                  onSelectionChanged: (v) => app.setTextScale(v.first),
                ),
              ),
              const SizedBox(height: 10),
              Text(s.textPreview, style: text.bodyLarge),
            ]),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.my_location_rounded,
            title: s.locationTracking,
            trailing: Switch(
              value: app.trackingEnabled,
              onChanged: (v) => app.setTrackingEnabled(v),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.locationTrackingHint, style: text.bodyMedium),
              if (denied) ...[
                const SizedBox(height: 10),
                Text(s.permissionDenied,
                    style: text.bodyMedium!.copyWith(color: const Color(0xFFB71C1C), fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: app.openPhoneSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: Text(s.openSettings),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.home_rounded,
            title: s.alertMyStation,
            trailing: Switch(
              value: app.alertMyStation,
              onChanged: app.setAlertMyStation,
            ),
            child: Text(s.alertMyStationHint, style: text.bodyMedium),
          ),
          const SizedBox(height: 12),
          _Card(
            icon: Icons.tune_rounded,
            title: s.demoMode,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.demoModeHint, style: text.bodyMedium),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DemoScreen(initialStationId: app.myStation.id)),
                  ),
                  icon: const Icon(Icons.play_circle_rounded),
                  label: Text(s.demoTitle),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Text(s.dataSource, style: text.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  static final _segStyle = SegmentedButton.styleFrom(
    minimumSize: const Size(0, 56),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.icon, required this.title, required this.child, this.trailing});
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

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
            ?trailing,
          ]),
          const SizedBox(height: 10),
          child,
        ]),
      ),
    );
  }
}
