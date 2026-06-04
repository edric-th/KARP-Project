/// Human-friendly wait-time label derived from real queue minutes.
/// Shared so the booking doctor-picker and the live queue read the same way.
String formatWait(int minutes) {
  if (minutes <= 0) return 'No wait';
  if (minutes < 60) return '~$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '~$h hr' : '~${h}h ${m}m';
}
