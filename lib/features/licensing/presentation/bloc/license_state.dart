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

/// One-shot result of an agent name/phone edit: either it synced to the server
/// or it only saved locally (server unreachable). The page maps it to a
/// snackbar, then it clears.
enum AgentSaveOutcome { synced, localOnly }

class LicenseState extends Equatable {
  final LicenseFlowStatus status;
  final LicenseStatus license;
  final List<SubscriptionPlan> plans;
  final bool plansLoading;

  /// Transient one-shot error; cleared on the next emit unless set again.
  final LicenseError? error;

  final String agentName;
  final String agentPhone;

  /// This device's identifier (for support / operator-driven activation).
  final String deviceId;

  /// True once the first server check has resolved. The router gate only holds
  /// on `/splash` before this — later re-checks (e.g. a manual refresh from the
  /// subscription screen) must NOT bounce the user back to the splash.
  final bool bootstrapped;

  /// True when this phone joined a shop rather than creating one.
  ///
  /// The gate needs it because [registered] is a **local** fact — it is just
  /// "have we cached a name" — and a member never registers. Without this a
  /// member whose licence is momentarily inactive (offline on the first launch
  /// after joining, a revoked seat, the owner's subscription lapsed) is read as
  /// a brand-new install and offered "create a new shop", which is how one till
  /// ends up as a second business.
  final bool isLinkedMember;

  /// True while an agent name/phone edit is being saved.
  final bool isSavingAgent;

  /// Transient one-shot result of the last agent edit; cleared on the next emit.
  final AgentSaveOutcome? agentSaveOutcome;

  const LicenseState({
    this.status = LicenseFlowStatus.initial,
    this.license = LicenseStatus.empty,
    this.plans = const [],
    this.plansLoading = false,
    this.error,
    this.agentName = '',
    this.agentPhone = '',
    this.deviceId = '',
    this.bootstrapped = false,
    this.isLinkedMember = false,
    this.isSavingAgent = false,
    this.agentSaveOutcome,
  });

  bool get isActive => license.isActive;

  /// The device has been registered on this install — the user has already
  /// entered their name/phone (and `create_device` was called). Drives the gate:
  /// unregistered → name/phone form; registered-but-inactive → plan selection.
  bool get registered => agentName.trim().isNotEmpty;

  /// A license operation is in flight — used by the gate to avoid bouncing the
  /// user between activation screens mid-request.
  bool get isBusy =>
      status == LicenseFlowStatus.checking ||
      status == LicenseFlowStatus.activating ||
      status == LicenseFlowStatus.requesting;

  LicenseState copyWith({
    LicenseFlowStatus? status,
    LicenseStatus? license,
    List<SubscriptionPlan>? plans,
    bool? plansLoading,
    LicenseError? error,
    String? agentName,
    String? agentPhone,
    String? deviceId,
    bool? bootstrapped,
    bool? isLinkedMember,
    bool? isSavingAgent,
    AgentSaveOutcome? agentSaveOutcome,
  }) {
    return LicenseState(
      status: status ?? this.status,
      license: license ?? this.license,
      plans: plans ?? this.plans,
      plansLoading: plansLoading ?? this.plansLoading,
      error: error,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
      deviceId: deviceId ?? this.deviceId,
      bootstrapped: bootstrapped ?? this.bootstrapped,
      isLinkedMember: isLinkedMember ?? this.isLinkedMember,
      isSavingAgent: isSavingAgent ?? this.isSavingAgent,
      // One-shot (like [error]): defaults to null each emit unless set.
      agentSaveOutcome: agentSaveOutcome,
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
        deviceId,
        bootstrapped,
        isLinkedMember,
        isSavingAgent,
        agentSaveOutcome,
      ];
}
