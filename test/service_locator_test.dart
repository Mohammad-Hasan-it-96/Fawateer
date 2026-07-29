// Guards the dependency graph itself.
//
// Every registration in `init()` is lazy, so nothing is *constructed* here —
// which is exactly why this test is cheap and why the failure it catches is
// otherwise invisible. GetIt throws on a duplicate registration at runtime, and
// `flutter analyze` cannot see it: the two lines are individually valid Dart.
// The app would build clean and then die on launch, before the first frame.
//
// This is not hypothetical. Two work streams touching `service_locator.dart`
// (the sync engine and sync enrollment) each registered `SyncApiClient` and
// `SyncCredentialStore`; the analyzer was happy and the app would not have
// started.
import 'package:billing_app/core/database/daos/sync_dao.dart';
import 'package:billing_app/core/service_locator.dart';
import 'package:billing_app/core/sync/sync_clock.dart';
import 'package:billing_app/features/sync/data/sync_engine.dart';
import 'package:billing_app/features/sync/data/sync_state_store.dart';
import 'package:billing_app/features/sync/domain/sync_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => sl.reset());

  test('init() registers every dependency exactly once', () async {
    // A duplicate registration throws ArgumentError here.
    await expectLater(init(), completes);
  });

  test('the sync graph is wired', () async {
    await init();
    // Registration only — resolving would build a real AppDatabase. Enough to
    // catch a dependency that was written but never registered, which fails at
    // the point of use (mid-sale, on a shop's phone) rather than at startup.
    expect(sl.isRegistered<SyncEngine>(), isTrue);
    expect(sl.isRegistered<SyncTransport>(), isTrue);
    expect(sl.isRegistered<SyncStateStore>(), isTrue);
    expect(sl.isRegistered<SyncDao>(), isTrue);
    expect(sl.isRegistered<SyncClock>(), isTrue);
  });
}
