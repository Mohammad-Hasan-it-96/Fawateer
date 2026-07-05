/// Pure, unit-testable enforcement guards for offline license usage. No storage
/// or clock capture happens here — callers pass in the cached timestamps and
/// "now", so the logic is deterministic and side-effect free.
class LicenseGuards {
  LicenseGuards._();

  /// How long the app keeps working offline after the last successful server
  /// check before it must reconnect. Re-tune per product policy.
  static const Duration offlineGrace = Duration(hours: 72);

  /// A device clock rolled back further than this (vs. the last trusted server
  /// time) is treated as tampering — a common trick to dodge expiry offline.
  static const Duration clockTamperThreshold = Duration(minutes: 5);

  /// True once too long has passed since [lastServerSync]. Unknown last-sync
  /// (never synced) is not treated as exceeded — activation handles that case.
  static bool isOfflineLimitExceeded(DateTime? lastServerSync, DateTime now) {
    if (lastServerSync == null) return false;
    return now.difference(lastServerSync) > offlineGrace;
  }

  /// True when the device clock is behind the last trusted server time by more
  /// than [clockTamperThreshold] — i.e. the user rolled the clock back.
  static bool isTimeTampered(DateTime? trustedServerTime, DateTime now) {
    if (trustedServerTime == null) return false;
    return trustedServerTime.difference(now) > clockTamperThreshold;
  }
}
