import 'package:flutter/material.dart';

import '../../domain/entities/dashboard_data.dart';

/// A compact ranked name → amount list (low-stock products, top debtors). Rows
/// are tappable so they can route into the relevant detail screen.
class MiniListCard extends StatelessWidget {
  final List<NamedAmount> items;
  final String Function(double) format;
  final Color amountColor;
  final IconData leadingIcon;
  final String emptyText;
  final void Function(NamedAmount)? onTap;

  const MiniListCard({
    super.key,
    required this.items,
    required this.format,
    required this.amountColor,
    required this.leadingIcon,
    required this.emptyText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Text(emptyText,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
    }
    return Column(
      children: [
        for (final item in items)
          InkWell(
            onTap: onTap == null ? null : () => onTap!(item),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Row(
                children: [
                  Icon(leadingIcon, size: 16, color: amountColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Text(format(item.amount),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: amountColor)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
