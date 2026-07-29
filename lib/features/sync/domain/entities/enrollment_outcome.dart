import 'package:equatable/equatable.dart';

import 'bootstrap_handoff.dart';
import 'sync_session.dart';

/// The result of enrolling this device — owner onboarding or member join
/// (ADR 0011). Pairs the durable [session] the device stores with the [bootstrap]
/// seed it uses to catch up with the shop before it starts pulling.
class EnrollmentOutcome extends Equatable {
  final SyncSession session;
  final BootstrapHandoff bootstrap;

  const EnrollmentOutcome({required this.session, required this.bootstrap});

  @override
  List<Object> get props => [session, bootstrap];
}
