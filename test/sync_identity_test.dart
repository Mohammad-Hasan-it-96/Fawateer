// Node id derivation (Plan 002, Phase 0). Pure — no device, no database.
import 'package:billing_app/core/sync/sync_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('syncNodeId', () {
    test('takes the first 16 characters of a real device id', () {
      // A real id is the 64-char hex SHA-256 DeviceIdentityService returns.
      final deviceId = 'a' * 32 + 'b' * 32;
      expect(syncNodeId(deviceId), 'a' * 16);
      expect(syncNodeId(deviceId).length, kNodeIdLength);
    });

    test('is stable — the same device always yields the same node', () {
      const id =
          '3f2a9c1e4b6d8079fe5a1c3b7d9e0f2a4c6b8d0e1f3a5c7b9d1e3f5a7c9b1d3e';
      expect(syncNodeId(id), syncNodeId(id));
      expect(syncNodeId(id), '3f2a9c1e4b6d8079');
    });

    test('passes through an id shorter than the node width', () {
      expect(syncNodeId('short'), 'short');
      expect(syncNodeId(''), '');
    });

    test('the fallback id collapses to one shared node — known and accepted',
        () {
      // Documented in syncNodeId: every device that fails to produce a platform
      // id truncates to the SAME node. Pinned so the collision is a deliberate,
      // visible property rather than something a future reader discovers during
      // a sync bug.
      expect(syncNodeId('fallback_device_id'), 'fallback_device_');
      expect(syncNodeId('fallback_device_id'), syncNodeId('fallback_device_id'));
    });
  });
}
