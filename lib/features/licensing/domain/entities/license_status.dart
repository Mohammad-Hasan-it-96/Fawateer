import 'package:equatable/equatable.dart';

/// Snapshot of the app's subscription/license state, blended from the last
/// server response and locally cached values so it stays meaningful offline.
///
/// The whole app gates on [isActive] — everything else is detail for the
/// activation UI.
class LicenseStatus extends Equatable {
  /// The server confirmed an active paid (or trial) subscription for this device.
  final bool isVerified;

  /// Subscription end date (from the server); null when never activated.
  final DateTime? expiresAt;

  /// Raw plan label from the server (e.g. "monthly", "12_months"), for display.
  final String? planName;

  final bool isTrial;

  /// Last successful server contact — drives the offline-grace window.
  final DateTime? lastServerSync;

  /// Device clock was rolled back past the tamper threshold (offline abuse).
  final bool timeTampered;

  /// Too long since the last successful server check (offline grace exceeded).
  final bool offlineLimitExceeded;

  const LicenseStatus({
    this.isVerified = false,
    this.expiresAt,
    this.planName,
    this.isTrial = false,
    this.lastServerSync,
    this.timeTampered = false,
    this.offlineLimitExceeded = false,
  });

  static const LicenseStatus empty = LicenseStatus();

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// The single gate the app checks: a verified, unexpired subscription not
  /// blocked by the offline-grace or clock-tamper guard.
  bool get isActive =>
      isVerified && !isExpired && !timeTampered && !offlineLimitExceeded;

  /// Whole days left until [expiresAt] (negative once expired); null if unset.
  int? get daysRemaining => expiresAt?.difference(DateTime.now()).inDays;

  LicenseStatus copyWith({
    bool? isVerified,
    DateTime? expiresAt,
    String? planName,
    bool? isTrial,
    DateTime? lastServerSync,
    bool? timeTampered,
    bool? offlineLimitExceeded,
  }) {
    return LicenseStatus(
      isVerified: isVerified ?? this.isVerified,
      expiresAt: expiresAt ?? this.expiresAt,
      planName: planName ?? this.planName,
      isTrial: isTrial ?? this.isTrial,
      lastServerSync: lastServerSync ?? this.lastServerSync,
      timeTampered: timeTampered ?? this.timeTampered,
      offlineLimitExceeded: offlineLimitExceeded ?? this.offlineLimitExceeded,
    );
  }

  @override
  List<Object?> get props => [
        isVerified,
        expiresAt,
        planName,
        isTrial,
        lastServerSync,
        timeTampered,
        offlineLimitExceeded,
      ];
}
