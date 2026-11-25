/// The four JPS / InfoBanjir river status levels, in increasing severity.
///
/// The order matters: the alert rules compare levels by [index].
enum FloodLevel { normal, alert, warning, danger }

extension FloodLevelX on FloodLevel {
  bool operator >=(FloodLevel other) => index >= other.index;
  bool operator >(FloodLevel other) => index > other.index;
  bool operator <(FloodLevel other) => index < other.index;
}
