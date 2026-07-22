/// Pure, unit-testable enforcement guards for offline license usage. No storage
/// or clock capture happens here — callers pass in the cached timestamps and
/// "now", so the logic is deterministic and side-effect free.
class LicenseGuards {
  LicenseGuards._();

  /// How long the app keeps working offline after the last successful server
  /// check before it must reconnect.
  ///
  /// **Sized for a shop, not for a server.** This was 72 hours, which bricks the
  /// POS after a three-day outage — an ordinary event where this app is sold,
  /// and one the shopkeeper cannot fix, because being locked out sends them to
  /// an activation screen that itself needs the connection they do not have.
  /// The downside of a long window is only that a server-side revocation takes
  /// longer to bite; the downside of a short one is a shop that cannot sell.
  /// Those are not close in cost.
  static const Duration offlineGrace = Duration(days: 30);

  /// A device clock rolled back further than this (vs. the last trusted server
  /// time) is treated as tampering — a common trick to dodge expiry offline.
  ///
  /// Was 5 minutes, which cannot tell tampering from a cheap Android that came
  /// back from a flat battery with its clock reset, or a timezone correction.
  /// A day of slack still catches the attack this guards (rolling back past an
  /// expiry date is worth far more than 48 hours) while leaving honest clock
  /// drift alone. Note the lockout it triggers is **silent** — there is no
  /// message explaining it — so a false positive here is close to unfixable for
  /// the user.
  static const Duration clockTamperThreshold = Duration(hours: 48);

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
