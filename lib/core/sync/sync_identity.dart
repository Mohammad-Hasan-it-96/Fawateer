/// This device's identity *as a sync participant* (Plan 002, Phase 0).
///
/// Deliberately derived from the licensing device id rather than minted fresh:
/// that id is already stable across reinstalls (only a factory reset changes
/// it), already hashed and salted so it leaks nothing about the handset, and is
/// already what the backend keys a device on. A second, independent identifier
/// would be one more thing that can disagree with the server.
library;

/// Characters of the device id that become the node id.
///
/// Sixteen hex characters = 64 bits, agreed with the backend as
/// `origin_device VARCHAR(16)` (see `docs/backend-replies/`). The full 64-char
/// SHA-256 was rejected on storage grounds: `origin_device` is stored on every
/// replicated row *and* embedded in every `updated_at` stamp, so the width is
/// paid twice per row, for every row, forever. 64 bits of a hash is far more
/// than enough to keep a handful of shop devices distinct.
const int kNodeIdLength = 16;

/// Reduce a licensing device id to this device's sync node id.
///
/// **The fallback caveat:** `DeviceIdentityService` returns the literal
/// `'fallback_device_id'` when the platform gives up no id at all (an
/// unsupported platform, or iOS before first unlock). That truncates to
/// `'fallback_device_'` — *identically for every such device*. Two fallback
/// devices would therefore share a node id, which breaks the HLC's final
/// tie-break and lets them collide. It is left as-is rather than papered over
/// with a random suffix, because a random node id would change on every launch
/// and break monotonicity far more often than the fallback occurs. Real Android
/// and iOS handsets — the entire shipped target — always yield a real id.
String syncNodeId(String deviceId) {
  if (deviceId.length <= kNodeIdLength) return deviceId;
  return deviceId.substring(0, kNodeIdLength);
}
