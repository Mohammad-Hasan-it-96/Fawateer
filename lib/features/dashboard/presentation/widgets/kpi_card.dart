import 'package:flutter/material.dart';

/// A single business-health tile: a label, a big value, an icon, and an optional
/// vs-previous-period delta chip (▲ green / ▼ red). Sized to sit two-per-row.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  /// Signed percent change vs the previous equal period; null hides the chip
  /// (no baseline, or a point-in-time metric like cash balance).
  final double? deltaPct;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.deltaPct,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const Spacer(),
              if (deltaPct != null) _DeltaChip(deltaPct!),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(value,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 19, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  final double pct;
  const _DeltaChip(this.pct);

  @override
  Widget build(BuildContext context) {
    final up = pct >= 0;
    final color = up ? Colors.green.shade600 : Colors.red.shade600;
    final text = '${up ? '+' : ''}${pct.toStringAsFixed(0)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
              size: 12, color: color),
          const SizedBox(width: 2),
          Text(text,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
