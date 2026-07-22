import 'package:flutter/material.dart';

import '../../../../core/service_locator.dart' as di;
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../licensing/domain/repositories/license_repository.dart';

/// Star-rating sheet posting to `add_review`.
///
/// Talks to [LicenseRepository] directly rather than through a BLoC: it owns no
/// app state, its result is a one-shot snackbar, and the only thing that
/// outlives it (the "already reviewed" flag) is written by the repository.
/// Returns true once the server accepted the review.
Future<bool> showRateAppSheet(BuildContext context) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _RateSheet(),
  );
  return result ?? false;
}

class _RateSheet extends StatefulWidget {
  const _RateSheet();

  @override
  State<_RateSheet> createState() => _RateSheetState();
}

class _RateSheetState extends State<_RateSheet> {
  final _commentC = TextEditingController();
  int _stars = 0;
  bool _sending = false;
  bool _failed = false;

  @override
  void dispose() {
    _commentC.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _sending) return;
    setState(() {
      _sending = true;
      _failed = false;
    });
    final result = await di.sl<LicenseRepository>().submitReview(
          stars: _stars,
          comment: _commentC.text,
        );
    if (!mounted) return;
    result.match(
      // Stay open on failure so the typed comment isn't thrown away and the
      // user can retry once they're back online.
      (_) => setState(() {
        _sending = false;
        _failed = true;
      }),
      (_) => Navigator.pop(context, true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2)),
          ),
          Text(l10n.rateTitle,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(l10n.ratePrompt,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final value = i + 1;
              final filled = value <= _stars;
              return IconButton(
                // Tooltip doubles as the accessibility label for the star.
                tooltip: '$value',
                iconSize: 38,
                onPressed:
                    _sending ? null : () => setState(() => _stars = value),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: filled ? Colors.amber.shade600 : scheme.outlineVariant,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentC,
            enabled: !_sending,
            maxLines: 3,
            maxLength: 1000, // matches the server's validation ceiling
            decoration: InputDecoration(
              hintText: l10n.rateCommentHint,
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_failed) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: scheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(l10n.rateFailed,
                      style: TextStyle(fontSize: 12, color: scheme.error)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style:
                  FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              // Disabled until a star is picked: a comment with no rating has
              // nothing to send (the server requires stars).
              onPressed: (_sending || _stars == 0) ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(l10n.rateSubmit,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
