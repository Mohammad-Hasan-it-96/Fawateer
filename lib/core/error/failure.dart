import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// A local storage / unexpected error (DB read/write failed, etc.).
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// The requested entity does not exist (e.g. no product for a scanned barcode).
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// An OS permission needed for the operation was denied (e.g. Bluetooth).
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

// Note: `message` carries developer/debug detail — it is NOT shown to users.
// Presentation maps the failure *type* to a localized string.
