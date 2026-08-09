import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final double elevation;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool isFullWidth;
  final TextStyle? textStyle;
  final bool isLoading;

  /// Space around the button. Generous by default because most screens use it
  /// as a page's single call to action — but the POS keeps it tight: every
  /// pixel here is a cart line the cashier can't see while scanning
  /// (Plan 013 #7).
  final EdgeInsetsGeometry margin;

  /// A shorter button for screens where it shares space with a list.
  ///
  /// Only the *chrome* shrinks — height and padding. The tap target stays at
  /// 44dp, above the 40dp floor a finger can reliably hit, because the button
  /// that takes the cashier to checkout is the last one that should need aiming.
  final bool dense;

  const PrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.elevation = 8.0,
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.isFullWidth = true,
    this.textStyle,
    this.isLoading = false,
    this.margin = const EdgeInsets.all(24.0),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      padding: dense ? const EdgeInsets.symmetric(vertical: 8) : padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: elevation,
      shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
      minimumSize:
          isFullWidth ? Size.fromHeight(dense ? 44 : 50) : null,
    );

    if (icon != null) {
      return Padding(
        padding: margin,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon),
          label: Text(
            label,
            style: textStyle,
          ),
          style: style,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: textStyle,
              ),
      ),
    );
  }
}
