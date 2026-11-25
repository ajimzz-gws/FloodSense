import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widgets.dart';

/// Full-screen alert shown when the user is affected by a rise in level.
/// Designed to be impossible to miss: whole screen in the level colour,
/// huge icon and words, one big button.
class AlertScreen extends StatefulWidget {
  const AlertScreen({super.key, required this.event, required this.s});
  final AlertEvent event;
  final S s;

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final s = widget.s;
    final style = LevelStyle.of(e.level);
    final fg = style.foreground;
    return Scaffold(
      backgroundColor: style.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          children: [
            Semantics(
              liveRegion: true,
              child: Column(children: [
                Icon(style.icon, size: 120, color: fg),
                const SizedBox(height: 8),
                Text(
                  s.alertTitle(e.level),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg, fontSize: 38, fontWeight: FontWeight.w900, height: 1.1),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Text(
              e.station.name,
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${s.waterLevel}: ${fmtMetres(e.metres)}',
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.whatToDo, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(s.levelAdvice(e.level), style: const TextStyle(fontSize: 21, height: 1.4, color: AppTheme.ink)),
              ]),
            ),
            const SizedBox(height: 28),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: fg,
                foregroundColor: style.background,
                minimumSize: const Size.fromHeight(68),
                textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.understood),
            ),
          ],
        ),
      ),
    );
  }
}
