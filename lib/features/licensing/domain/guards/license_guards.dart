/// Pure, unit-testable enforcement guards for offline license usage. No storage
/// or clock capture happens here — callers pass in the cached timestamps and
/// "now", so the logic is deterministic and side-effect free.
class LicenseGuards {
  LicenseGuards._();

  /// How long the app keeps working offline after the last successful server
  /// check before it must reconnect.
  ///
  /// **Sized for a shop, not for a server.** Was 30 days; tightened to 7 after
  /// adopting Smart-Agent's recoverable lock UX: the app now *warns* from
  /// [offlineWarnAfter] and, once this limit trips, shows a dedicated
  /// "reconnect to verify" screen with a Retry button — not a silent redirect
  /// to the plans page that looks like a payment demand. A week still rides
  /// out the multi-day outages that are ordinary where this app is sold.
  ///
  /// Note the only thing this window bounds is **server-side revocation
  /// latency**: subscription/trial expiry is enforced locally from the cached
  /// `expiresAt` and locks the app offline regardless of this guard.
  static const Duration offlineGrace = Duration(days: 7);

  /// When the soft "connect to the internet soon" warning starts showing.
  /// Warning only — nothing locks until [offlineGrace].
  static const Duration offlineWarnAfter = Duration(days: 3);

  /// A device clock rolled back further than this (vs. the last trusted server
  /// time) is treated as tampering — a common trick to dodge expiry offline.
  ///
  /// Was 5 minutes in the Smart-Agent reference app, which cannot tell
  /// tampering from a cheap Android that came back from a flat battery with
  /// its clock reset, or a manual clock correction. Two days of slack still
  /// catches the attack this guards against (rolling back past an expiry date
  /// is worth far more than 48 hours) while leaving honest clock drift alone.
  static const Duration clockTamperThreshold = Duration(hours: 48);

  /// True once too long has passed since [lastServerSync]. Unknown last-sync
  /// (never synced) is not treated as exceeded — activation handles that case.
  static bool isOfflineLimitExceeded(DateTime? lastServerSync, DateTime now) {
    if (lastServerSync == null) return false;
    return now.difference(lastServerSync) > offlineGrace;
  }

  /// True once the soft warning should show (still unlocked): more than
  /// [offlineWarnAfter] since the last successful server contact.
  static bool isOfflineWarning(DateTime? lastServerSync, DateTime now) {
    if (lastServerSync == null) return false;
    return now.difference(lastServerSync) > offlineWarnAfter;
  }

  /// Whole days since the last successful server contact (for the warning
  /// banner's message); null when never synced.
  static int? daysOffline(DateTime? lastServerSync, DateTime now) =>
      lastServerSync == null ? null : now.difference(lastServerSync).inDays;

  /// True when the device clock is behind the last trusted server time by more
  /// than [clockTamperThreshold] — i.e. the user rolled the clock back.
  ///
  /// [timeOffsetSeconds] is the server-minus-device skew recorded at the last
  /// successful sync (idea adopted from Smart-Agent): a device whose clock
  /// legitimately runs behind the server would otherwise eat into the tamper
  /// budget. Adding the known skew to the device clock compares like with like.
  static bool isTimeTampered(DateTime? trustedServerTime, DateTime now,
      {int timeOffsetSeconds = 0}) {
    if (trustedServerTime == null) return false;
    final adjustedNow = now.add(Duration(seconds: timeOffsetSeconds));
    return trustedServerTime.difference(adjustedNow) > clockTamperThreshold;
  }

  /// True when the device clock sits more than [clockTamperThreshold] behind
  /// the highest device time ever observed ([maxSeenTime], persisted
  /// monotonically). Catches a rollback even when the device hasn't synced
  /// with the server recently — the case the trusted-time check can't see.
  /// No skew correction: both timestamps come from the same device clock.
  static bool isClockRolledBack(DateTime? maxSeenTime, DateTime now) {
    if (maxSeenTime == null) return false;
    return maxSeenTime.difference(now) > clockTamperThreshold;
  }
}
