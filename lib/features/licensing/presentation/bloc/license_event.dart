part of 'license_bloc.dart';

abstract class LicenseEvent extends Equatable {
  const LicenseEvent();
  @override
  List<Object?> get props => [];
}

/// Verify the device with the server (dispatched at startup) and refresh state.
class CheckLicenseEvent extends LicenseEvent {}

/// Fetch the subscription plan catalog.
class LoadPlansEvent extends LicenseEvent {}

/// Register/activate this device with the agent's name + phone.
class ActivateLicenseEvent extends LicenseEvent {
  final String name;
  final String phone;
  const ActivateLicenseEvent({required this.name, required this.phone});
  @override
  List<Object?> get props => [name, phone];
}

/// File an operator-driven purchase request for [plan] via [contactMethod].
class RequestPlanEvent extends LicenseEvent {
  final String name;
  final String phone;
  final SubscriptionPlan plan;
  final String contactMethod;
  const RequestPlanEvent({
    required this.name,
    required this.phone,
    required this.plan,
    required this.contactMethod,
  });
  @override
  List<Object?> get props => [name, phone, plan, contactMethod];
}
