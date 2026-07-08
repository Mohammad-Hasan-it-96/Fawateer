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

/// A uniqueness constraint was violated (e.g. a duplicate product barcode).
class DuplicateFailure extends Failure {
  const DuplicateFailure(super.message);
}

/// No connectivity / request timed out — the server could not be reached. The
/// app is likely offline; callers may fall back to cached state within grace.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// The server was reached but returned an error or an unexpected response.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// The operation conflicts with existing state and was refused (e.g. deleting a
/// customer who still has ledger entries).
class ConflictFailure extends Failure {
  const ConflictFailure(super.message);
}

// Note: `message` carries developer/debug detail — it is NOT shown to users.
// Presentation maps the failure *type* to a localized string.
