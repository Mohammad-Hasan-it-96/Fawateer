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

  LicenseBloc({required this.repository}) : super(const LicenseState()) {
    on<CheckLicenseEvent>(_onCheck);
    on<ActivateLicenseEvent>(_onActivate);
    on<LoadPlansEvent>(_onLoadPlans);
    on<RequestPlanEvent>(_onRequestPlan);
  }

  Future<void> _onCheck(
      CheckLicenseEvent event, Emitter<LicenseState> emit) async {
    try {
      final agent = await repository.cachedAgent();
      final deviceId =
          state.deviceId.isEmpty ? await repository.deviceId() : state.deviceId;

      // Brand-new device (never registered here): skip the server poll and send
      // the user straight to the activation form to enter name/phone. Only after
      // they register (create_device) does check_device have anything to find —
      // polling it first just returns "device not found" (404). This also means
      // a fresh install performs no network call at startup at all.
      final neverRegistered = agent.name == null || agent.name!.trim().isEmpty;
      if (neverRegistered) {
        emit(state.copyWith(
          status: LicenseFlowStatus.unlicensed,
          deviceId: deviceId,
          bootstrapped: true,
        ));
        return;
      }

      emit(state.copyWith(
        status: LicenseFlowStatus.checking,
        agentName: agent.name,
        agentPhone: agent.phone,
        deviceId: deviceId,
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
