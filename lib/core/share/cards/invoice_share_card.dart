import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// One printed line on the shared invoice card.
class InvoiceShareLine {
  final String name;
  final double quantity;
  final double unitPrice; // resolved SP unit price
  final double lineTotal; // net of the line discount
  const InvoiceShareLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}

/// A styled, shareable invoice/receipt rendered as a colored card (captured to
/// PNG by `captureWidgetToPng`). Deliberately NOT the monochrome thermal
/// `ReceiptImage` — this is a clean branded image for WhatsApp, not a printer
/// bitmap. Fed a normalized view model so it works from both the checkout cart
/// and a stored invoice.
class InvoiceShareCard extends StatelessWidget {
  final AppLocalizations l10n;
  final String currency;

  final String shopName;
  final String shopAddress1;
  final String shopAddress2;
  final String shopPhone;
  final String footer;

  final String invoiceShortId;
  final String dateText;
  final String timeText;

  /// Payment label + customer (null → hide the row, e.g. a plain checkout copy).
  final String? paymentLabel;
  final String? customerName;

  final List<InvoiceShareLine> lines;
  final double subtotal;
  final double discount; // combined line + cart discount
  final double total;

  const InvoiceShareCard({
    super.key,
    required this.l10n,
    required this.currency,
    required this.shopName,
    required this.shopAddress1,
    required this.shopAddress2,
    required this.shopPhone,
    required this.footer,
    required this.invoiceShortId,
    required this.dateText,
    required this.timeText,
    required this.paymentLabel,
    required this.customerName,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  String _m(double v) => '$currency${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      accent: AppTheme.primaryColor,
      children: [
        // ── Shop header ──
        Text(
          shopName.isEmpty ? l10n.invoiceDetails : shopName,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (shopAddress1.isNotEmpty || shopAddress2.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [shopAddress1, shopAddress2].where((s) => s.isNotEmpty).join('، '),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        if (shopPhone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(shopPhone,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        const SizedBox(height: 14),
        const _DashedDivider(),
        const SizedBox(height: 10),

        // ── Meta ──
        _metaRow(l10n.invoiceNumber, invoiceShortId, mono: true),
        _metaRow(l10n.dateLabel, dateText),
        _metaRow(l10n.timeLabel, timeText),
        if (paymentLabel != null) _metaRow(l10n.paymentType, paymentLabel!),
        if (customerName != null && customerName!.isNotEmpty)
          _metaRow(l10n.customerLabel, customerName!),

        const SizedBox(height: 10),
        const _DashedDivider(),
        const SizedBox(height: 6),

        // ── Items ──
        for (final line in lines) _lineRow(line),

        const SizedBox(height: 4),
        const _DashedDivider(),
        const SizedBox(height: 8),

        // ── Totals ──
        if (discount > 0.005) ...[
          _totalRow(l10n.subtotalLabel, _m(subtotal), muted: true),
          _totalRow(l10n.discountLabel, '- ${_m(discount)}',
              color: Colors.red.shade600),
          const SizedBox(height: 4),
        ],
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.grandTotal,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(_m(total),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
            ],
          ),
        ),

        const SizedBox(height: 14),
        Text(
          footer.isNotEmpty ? footer : l10n.receiptThankYou,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: mono ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }

  Widget _lineRow(InvoiceShareLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                Text('${formatQty(line.quantity)} × ${_m(line.unitPrice)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_m(line.lineTotal),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value,
      {bool muted = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: muted ? Colors.grey[500] : Colors.grey[700])),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.grey[800])),
        ],
      ),
    );
  }
}

/// Shared card chrome: a white rounded card with a colored accent bar on top,
/// a subtle border, and consistent padding. Reused by every share card.
class _CardShell extends StatelessWidget {
  final Color accent;
  final List<Widget> children;
  const _CardShell({required this.accent, required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(height: 6, color: accent),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A thin dashed separator, softer than a solid rule for a receipt look.
class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 4.0;
        const gap = 3.0;
        final count = (constraints.maxWidth / (dash + gap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: dash, height: 1, color: Colors.grey[300]),
          ),
        );
      },
    );
  }
}

/// Exposed so sibling cards reuse the exact same shell + divider.
class ShareCardShell extends StatelessWidget {
  final Color accent;
  final List<Widget> children;
  const ShareCardShell({super.key, required this.accent, required this.children});

  @override
  Widget build(BuildContext context) =>
      _CardShell(accent: accent, children: children);
}

/// Exposed dashed divider for sibling cards.
class ShareCardDivider extends StatelessWidget {
  const ShareCardDivider({super.key});
  @override
  Widget build(BuildContext context) => const _DashedDivider();
}
