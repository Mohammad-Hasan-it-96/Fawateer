/// Shared SnackBar display durations (Plan 011 #7).
///
/// Notifications were lingering too long — Flutter's ~4s default plus several
/// explicit 5–6s snackbars — which the shopkeeper flagged as slow (a
/// "printer not connected" notice that hangs around covers the UI). These
/// constants halve those so a transient notice clears fast; route notification
/// snackbars through them instead of hand-picking a `Duration`.
class AppSnackDuration {
  const AppSnackDuration._();

  /// Transient status/error notices — halved from Flutter's ~4s default.
  static const Duration brief = Duration(seconds: 2);

  /// Longer or actionable notices that still need a beat to read — halved from
  /// the old 5–6s values.
  static const Duration normal = Duration(seconds: 3);
}
