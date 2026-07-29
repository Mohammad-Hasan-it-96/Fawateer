import 'package:equatable/equatable.dart';

/// A single-use invitation for another device to join this business
/// (`POST /api/v1/sync/enroll/token`, owner role only).
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

  const JoinToken({required this.token, required this.expiresAt});

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
    );
  }

  @override
  List<Object> get props => [token, expiresAt];
}
