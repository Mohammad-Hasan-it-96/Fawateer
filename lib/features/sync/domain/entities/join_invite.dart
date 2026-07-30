import 'package:equatable/equatable.dart';

import 'join_token.dart';

/// What the owner actually shows the joining device: the server's single-use
/// [token], plus the SHA-256 of the bootstrap snapshot the owner just uploaded.
///
/// **The hash travels with the invitation, not with the download** (pinned
/// 2026-07-29 H2). A hash handed back by the server alongside the file only
/// certifies that the bytes survived transit — it is the same party vouching for
/// its own delivery. One the owner computed locally and passed out of band makes
/// the integrity check genuinely owner→joiner. That is also why the QR cannot be
/// rendered until the upload has finished: the hash does not exist until the
/// snapshot does.
///
/// **The typed fallback carries a deliberately narrower guarantee.** A shop phone
/// with a cracked lens still has to be able to join (Plan 002 Q2), and nobody is
/// going to key in 64 hex characters correctly — so a typed code is the token
/// alone, and the joiner falls back to verifying against the hash the server
/// declares. That still catches a truncated or corrupted download; what it drops
/// is protection against a server that substitutes the file. The upload already
/// requires the owner's own device token (H1), so substitution means the server
/// itself, not an intruder who photographed the QR. Scanning is the better path
/// and is what the UI leads with; typing is the fallback, and this is what it
/// costs.
class JoinInvite extends Equatable {
  final JoinToken token;

  /// Hex SHA-256 of the uploaded snapshot, or null when there was nothing to
  /// seed (the shop's first device enrolling into an empty business).
  final String? snapshotSha256;

  const JoinInvite({required this.token, this.snapshotSha256});

  /// Prefix + version, so a future payload change is detectable rather than
  /// silently mis-parsed as a bare token.
  static const _prefix = 'FW1';

  /// The string the QR encodes. A bare token when there is no snapshot, so a
  /// seedless invite stays as short — and as scannable — as it was before.
  String encode() {
    final sha = snapshotSha256;
    if (sha == null || sha.isEmpty) return token.token;
    return '$_prefix:${token.token}:$sha';
  }

  /// Parse whatever arrived — a scanned payload or something typed by hand.
  ///
  /// Anything that is not our own prefixed form is treated as a **bare token**
  /// rather than rejected: that is exactly what the typed fallback produces, and
  /// it is also what an older build's QR looks like.
  static ({String token, String? sha256}) decode(String raw) {
    final value = raw.trim();
    if (!value.startsWith('$_prefix:')) return (token: value, sha256: null);

    final body = value.substring(_prefix.length + 1);
    // Split at the LAST separator: the hash is a fixed-width tail, while the
    // token is opaque and could contain a colon of its own.
    final cut = body.lastIndexOf(':');
    if (cut <= 0) return (token: body, sha256: null);
    final sha = body.substring(cut + 1);
    return (
      token: body.substring(0, cut),
      sha256: sha.isEmpty ? null : sha,
    );
  }

  bool get hasSnapshot => (snapshotSha256?.isNotEmpty ?? false);

  @override
  List<Object?> get props => [token, snapshotSha256];
}
