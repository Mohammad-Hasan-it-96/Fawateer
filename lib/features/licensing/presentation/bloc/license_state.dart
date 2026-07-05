part of 'license_bloc.dart';

enum LicenseFlowStatus {
  /// Not yet checked (app just launched).
  initial,

  /// Verifying with the server.
  checking,

  /// Verified & valid — the app gate is open.
  active,

  /// No valid subscription — the gate is closed (show activation UI).
  unlicensed,

  /// An activation request is in flight.
  activating,

  /// A plan purchase request is in flight.
  requesting,

  /// A pending purchase request was filed with the operator.
  requestSent,
}

/// Localizable error class; the page maps it to a string so no user-facing
/// English lives in the BLoC.
enum LicenseError { network, server, unexpected }

class LicenseState extends Equatable {
  final LicenseFlowStatus status;
  final LicenseStatus license;
  final List<SubscriptionPlan> plans;
  final bool plansLoading;

  /// Transient one-shot error; cleared on the next emit unless set again.
  final LicenseError? error;

  final String agentName;
  final String agentPhone;

  /// True once the first server check has resolved. The router gate only holds
  /// on `/splash` before this — later re-checks (e.g. a manual refresh from the
  /// subscription screen) must NOT bounce the user back to the splash.
  final bool bootstrapped;

  const LicenseState({
    this.status = LicenseFlowStatus.initial,
    this.license = LicenseStatus.empty,
    this.plans = const [],
    this.plansLoading = false,
    this.error,
    this.agentName = '',
    this.agentPhone = '',
    this.bootstrapped = false,
  });

  bool get isActive => license.isActive;

  LicenseState copyWith({
    LicenseFlowStatus? status,
    LicenseStatus? license,
    List<SubscriptionPlan>? plans,
    bool? plansLoading,
    LicenseError? error,
    String? agentName,
    String? agentPhone,
    bool? bootstrapped,
  }) {
    return LicenseState(
      status: status ?? this.status,
      license: license ?? this.license,
      plans: plans ?? this.plans,
      plansLoading: plansLoading ?? this.plansLoading,
      error: error,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      bootstrapped: bootstrapped ?? this.bootstrapped,
    );
  }

  @override
  List<Object?> get props => [
        status,
        license,
        plans,
        plansLoading,
        error,
        agentName,
        agentPhone,
        bootstrapped,
      ];
}
