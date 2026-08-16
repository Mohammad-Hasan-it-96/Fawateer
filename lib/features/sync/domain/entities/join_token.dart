import 'package:equatable/equatable.dart';

/// A single-use invitation for another device to join this business
/// (`POST /api/v1/sync/join-tokens`, owner role only).
///
/// **Short-lived and single-use by design.** A leaked durable QR would let an
/// intruder join a shop's financial data, so the token is minted on demand,
/// expires in minutes, and is consumed the moment a device redeems it. That is
/// also why nothing caches it: a code still on screen after it was used is a
/// code the owner will try to use again.
class JoinToken extends Equatable {
  /// The code the joining device sends. Shown as a QR *and* as text — a shop
  /// phone with a broken camera, or a screen too scratched to scan, still has
  /// to be able to join (Plan 002 Q2 keeps a typed fallback for exactly this).
  final String token;

  final DateTime expiresAt;

  /// Where this device should POST the bootstrap snapshot bound to [token].
  ///
  /// The 2026-07-28 §H reply says the enrollment family returns "upload target +
  /// signed-URL download" but never pins the field or the path, so this is the
  /// one shape in the whole contract we are guessing at: absent, the caller
  /// falls back to a conventional endpoint on the sync base. Worth confirming
  /// against the first server build.
  final String? uploadUrl;

  const JoinToken({
    required this.token,
    required this.expiresAt,
    this.uploadUrl,
  });

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);

  Duration remainingAt(DateTime now) {
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  factory JoinToken.fromJson(Map<String, dynamic> json, {DateTime? now}) {
    final raw = json['expires_at'];
    DateTime? expiry;
    if (raw is int) {
      expiry = DateTime.fromMillisecondsSinceEpoch(raw * 1000);
    } else if (raw != null) {
      expiry = DateTime.tryParse(raw.toString())?.toLocal();
    }
    return JoinToken(
      token: json['join_token']?.toString() ?? json['token']?.toString() ?? '',
      // A missing or unparseable expiry is treated as *already expired* rather
      // than as "no expiry". Guessing generously here would be inventing a
      // durable credential out of a malformed response.
      expiresAt: expiry ?? (now ?? DateTime.now()),
      uploadUrl: json['upload_url']?.toString(),
    );
  }

  @override
  List<Object?> get props => [token, expiresAt, uploadUrl];
}
