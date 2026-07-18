import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Which role the button plays. Maps onto the themed Material buttons rather
/// than restyling them, so [AppButton] stays in sync with `AppTheme` for free.
enum AppButtonVariant { filled, outlined, text }

/// The app's primary action button.
///
/// Exists to kill two recurring patterns: hand-rolled `styleFrom` at the call
/// site (which drifts from the theme), and the copy-pasted
/// "swap the label for a CircularProgressIndicator while saving" block.
///
/// It carries **no strings of its own** — a busy button shows a spinner, not a
/// localized "saving…" label — because user-facing text belongs in the page's
/// ARB lookups, not in a shared widget.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.busy = false,
    this.fullWidth = true,
  });

  final String label;

  /// `null` disables the button. A [busy] button is also disabled, so an
  /// in-flight action can't be fired twice by an impatient double-tap.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool busy;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = busy ? null : onPressed;
    final child = busy ? const _ButtonSpinner() : Text(label);

    final Widget button = switch (variant) {
      AppButtonVariant.filled => icon != null && !busy
          ? FilledButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon, size: 20),
              label: child)
          : FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.outlined => icon != null && !busy
          ? OutlinedButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon, size: 20),
              label: child)
          : OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.text => icon != null && !busy
          ? TextButton.icon(
              onPressed: effectiveOnPressed,
              icon: Icon(icon, size: 20),
              label: child)
          : TextButton(onPressed: effectiveOnPressed, child: child),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Sized to the button's text line so swapping label→spinner doesn't change the
/// button's height and shift the layout around it.
class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppTokens.spaceXl - 4,
      width: AppTokens.spaceXl - 4,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          DefaultTextStyle.of(context).style.color ?? Colors.white,
        ),
      ),
    );
  }
}
