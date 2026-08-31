import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/license_status.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/license_repository.dart';

part 'license_event.dart';
part 'license_state.dart';

/// Owns subscription/license state for the whole app. Registered as a singleton
/// (not a factory) because the GoRouter gate and the widget tree must observe
/// the *same* instance — the router redirects off [LicenseState.status].
class LicenseBloc extends Bloc<LicenseEvent, LicenseState> {
  final LicenseRepository repository;

  /// Buffer added past the exact expiry moment before re-checking, so the
  /// check lands strictly after it. Injectable so tests can use milliseconds.
  final Duration expiryCheckBuffer;

  /// Whether this phone holds a **member** sync seat — it joined a shop rather
  /// than creating one.
  ///
  /// A function rather than a `SyncCredentialStore`, so licensing keeps no
  /// import of the sync feature: sync already depends on licensing for the
  /// device id and the push token, and pointing the arrow both ways would make
  /// the two impossible to reason about separately. Same shape as the token
  /// getter `SyncApiTransport` takes.
  ///
  /// Defaults to "no seat", which is every device that has never joined a shop.
  final Future<bool> Function() isLinkedMember;

  LicenseBloc({
    required this.repository,
    Future<bool> Function()? isLinkedMember,
    this.expiryCheckBuffer = const Duration(seconds: 10),
  })  : isLinkedMember = (isLinkedMember ?? _noSeat),
        super(const LicenseState()) {
    on<CheckLicenseEvent>(_onCheck);
    on<ActivateLicenseEvent>(_onActivate);
    on<UpdateAgentEvent>(_onUpdateAgent);
    on<LoadPlansEvent>(_onLoadPlans);
    on<RequestPlanEvent>(_onRequestPlan);
  }

  static Future<bool> _noSeat() async => false;

  /// Re-check scheduled for the moment the subscription expires (capped at
  /// 24h, re-arming itself for far-off expiries). Without it, expiry only
  /// bites on the next navigation or restart — [LicenseStatus.isExpired] reads
  /// `DateTime.now()`, but nothing re-evaluates the gate on pure time passage,
  /// so a POS left open on one screen would keep selling past its end date.
  /// The 24h cap doubles as a daily re-check for devices that are never
  /// restarted. Offline at fire time is fine: the cached expiry still locks.
  Timer? _expiryTimer;

  void _armExpiryTimer(LicenseState s) {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    final expiresAt = s.license.expiresAt;
    if (!s.license.isActive || expiresAt == null) return;
    // Small buffer past the exact moment so the re-check lands after it.
    final untilExpiry = expiresAt.difference(DateTime.now()) + expiryCheckBuffer;
    const cap = Duration(hours: 24);
    _expiryTimer = Timer(untilExpiry < cap ? untilExpiry : cap,
        () => add(CheckLicenseEvent()));
  }

  @override
  void onChange(Change<LicenseState> change) {
    super.onChange(change);
    // NOTE: must arm off [Change.nextState] — inside onChange, `state` still
    // holds the previous state, whose license may predate this emission.
    _armExpiryTimer(change.nextState);
  }

  @override
  Future<void> close() {
    _expiryTimer?.cancel();
    return super.close();
  }

  Future<void> _onCheck(
      CheckLicenseEvent event, Emitter<LicenseState> emit) async {
    try {
      final agent = await repository.cachedAgent();
      final deviceId =
          state.deviceId.isEmpty ? await repository.deviceId() : state.deviceId;

      // Does this phone hold a member seat? Read on every check, not cached:
      // a join, and a revoke, both change it without restarting the app.
      final linked = await isLinkedMember();

      // Brand-new device (never registered here): skip the server poll and send
      // the user straight to the activation form to enter name/phone. Only after
      // they register (create_device) does check_device have anything to find —
      // polling it first just returns "device not found" (404). This also means
      // a fresh install performs no network call at startup at all.
      //
      // **Unless it has joined a shop.** A phone that took the first-run "join"
      // door never registers — it has no name or number of its own to give, and
      // the backend deliberately creates its `device_subscriptions` row with
      // both null, covering it from the owner's business instead (ADR 0011
      // Decision 2). So `agent.name` is empty on a perfectly licensed till, and
      // skipping the poll here means the app never asks — the seat is real, the
      // server would answer verified, and the phone sits on the first-run fork
      // being offered a shop it already belongs to. The whole backend change
      // would have looked like it did nothing.
      final neverRegistered = agent.name == null || agent.name!.trim().isEmpty;
      if (neverRegistered && !linked) {
        emit(state.copyWith(
          status: LicenseFlowStatus.unlicensed,
          deviceId: deviceId,
          isLinkedMember: false,
          bootstrapped: true,
        ));
        return;
      }

      emit(state.copyWith(
        status: LicenseFlowStatus.checking,
        agentName: agent.name,
        agentPhone: agent.phone,
        deviceId: deviceId,
        isLinkedMember: linked,
      ));
      final result = await repository.checkLicense();
      result.fold(
        (failure) => emit(state.copyWith(
          status: state.license.isActive
              ? LicenseFlowStatus.active
              : LicenseFlowStatus.unlicensed,
          error: _mapError(failure),
          bootstrapped: true,
        )),
        (status) => emit(state.copyWith(
          status: status.isActive
              ? LicenseFlowStatus.active
              : LicenseFlowStatus.unlicensed,
          license: status,
          bootstrapped: true,
        )),
      );
    } catch (e) {
      // Safety net: nothing in the check must ever leave the splash spinning. On
      // any unexpected error, bootstrap as unlicensed so the gate can proceed to
      // the activation screen instead of hanging.
      emit(state.copyWith(
        status: state.license.isActive
            ? LicenseFlowStatus.active
            : LicenseFlowStatus.unlicensed,
        error: LicenseError.unexpected,
        bootstrapped: true,
      ));
    }
  }

  Future<void> _onActivate(
      ActivateLicenseEvent event, Emitter<LicenseState> emit) async {
    emit(state.copyWith(
      status: LicenseFlowStatus.activating,
      agentName: event.name,
      agentPhone: event.phone,
    ));
    final result =
        await repository.activate(name: event.name, phone: event.phone);
    result.fold(
      (failure) => emit(state.copyWith(
          status: LicenseFlowStatus.unlicensed,
          error: _mapError(failure),
          bootstrapped: true)),
      (status) => emit(state.copyWith(
        status: status.isActive
            ? LicenseFlowStatus.active
            : LicenseFlowStatus.unlicensed,
        license: status,
        bootstrapped: true,
      )),
    );
  }

  Future<void> _onUpdateAgent(
      UpdateAgentEvent event, Emitter<LicenseState> emit) async {
    emit(state.copyWith(isSavingAgent: true));
    final result =
        await repository.updateAgent(name: event.name, phone: event.phone);
    // The local save always succeeds, so reflect the new name/phone regardless;
    // the outcome only tells the user whether the server was synced too.
    emit(state.copyWith(
      isSavingAgent: false,
      agentName: event.name,
      agentPhone: event.phone,
      agentSaveOutcome: result.isRight()
          ? AgentSaveOutcome.synced
          : AgentSaveOutcome.localOnly,
    ));
  }

  Future<void> _onLoadPlans(
      LoadPlansEvent event, Emitter<LicenseState> emit) async {
    emit(state.copyWith(plansLoading: true));
    final result = await repository.getPlans();
    result.fold(
      (failure) =>
          emit(state.copyWith(plansLoading: false, error: _mapError(failure))),
      (plans) => emit(state.copyWith(plansLoading: false, plans: plans)),
    );
  }

  Future<void> _onRequestPlan(
      RequestPlanEvent event, Emitter<LicenseState> emit) async {
    emit(state.copyWith(status: LicenseFlowStatus.requesting));
    final result = await repository.requestPlan(
      name: event.name,
      phone: event.phone,
      plan: event.plan,
      contactMethod: event.contactMethod,
    );
    result.fold(
      (failure) => emit(state.copyWith(
          status: LicenseFlowStatus.unlicensed, error: _mapError(failure))),
      (_) => emit(state.copyWith(status: LicenseFlowStatus.requestSent)),
    );
  }

  LicenseError _mapError(Failure failure) {
    if (failure is NetworkFailure) return LicenseError.network;
    if (failure is ServerFailure) return LicenseError.server;
    return LicenseError.unexpected;
  }
}
