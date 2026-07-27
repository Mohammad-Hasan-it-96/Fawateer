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

/// A backup file cannot be restored into this app: it was produced by a NEWER
/// app version (its schemaVersion is ahead of ours — restoring would corrupt
/// data via a missing downgrade path) or its checksum failed (corrupt/tampered).
class IncompatibleFailure extends Failure {
  const IncompatibleFailure(super.message);
}

/// A restore failed *after* the live database connection had already been
/// closed. The data on disk is intact (the swap is rolled back, and the
/// `.pre-restore` copy is kept either way) — but the **running app** can no
/// longer reach SQLite, so every subsequent query throws until it is restarted.
///
/// This is deliberately a distinct type rather than a [CacheFailure]: the two
/// need opposite UI. An ordinary failure is a snackbar the user shrugs off; this
/// one must tell them to reopen the app, or they are left tapping around a shell
/// that looks corrupted while their data is actually fine.
class RestoreIncompleteFailure extends Failure {
  const RestoreIncompleteFailure(super.message);
}

// Note: `message` carries developer/debug detail — it is NOT shown to users.
// Presentation maps the failure *type* to a localized string.
