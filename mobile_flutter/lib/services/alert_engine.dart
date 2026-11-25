import '../models/flood_level.dart';

/// Result of checking one station against the alert rules.
class AlertDecision {
  const AlertDecision({required this.notify, required this.lastNotified});

  /// Show an alert to the user now.
  final bool notify;

  /// The level to remember as "already told the user about".
  final FloodLevel lastNotified;
}

/// Pure alert rules, kept free of Flutter so they are easy to unit test.
///
/// The idea: tell people in the impact zone once each time the river moves
/// *up* a level (Normal -> Alert -> Warning -> Danger). No repeats while the
/// level stays the same, and when the water falls the memory drops with it,
/// so a second rise alerts again.
class AlertEngine {
  static AlertDecision decide({
    required FloodLevel current,
    required FloodLevel lastNotified,
    required bool inZone,
  }) {
    // Water has gone down: forget the higher level, no alert.
    if (current < lastNotified) {
      return AlertDecision(notify: false, lastNotified: current);
    }
    // Water has gone up into Alert or worse, and the user is affected.
    if (current > lastNotified && current >= FloodLevel.alert && inZone) {
      return AlertDecision(notify: true, lastNotified: current);
    }
    // Same level, or the user is outside the zone: remember nothing new,
    // so they are alerted if they walk into the zone later.
    return AlertDecision(notify: false, lastNotified: lastNotified);
  }
}
