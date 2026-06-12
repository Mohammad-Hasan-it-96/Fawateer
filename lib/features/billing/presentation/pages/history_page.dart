import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../bloc/history_bloc.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Sales History', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<HistoryBloc, HistoryState>(
        builder: (context, state) {
          if (state.status == HistoryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == HistoryStatus.error) {
            return Center(
              child: Text('Error: ${state.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final currency = (context.watch<ShopBloc>().state is ShopLoaded)
              ? (context.read<ShopBloc>().state as ShopLoaded)
                  .shop
                  .currencySymbol
              : '';

          return Column(
            children: [
              // Daily summary card
              _DailySummaryCard(
                currency: currency,
                total: state.todayTotal,
                count: state.todayCount,
              ),

              // Invoice list
              Expanded(
                child: state.invoices.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: state.invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = state.invoices[index];
                          return _InvoiceCard(
                            invoice: invoice,
                            currency: currency,
                            items: state.itemsCache[invoice.id],
                            onExpand: () => context
                                .read<HistoryBloc>()
                                .add(LoadInvoiceDetailsEvent(invoice.id)),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          const Text('No sales yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Completed sales will appear here.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  final String currency;
  final double total;
  final int count;

  const _DailySummaryCard({
    required this.currency,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TODAY'S SALES",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$currency${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'invoices',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatefulWidget {
  final Invoice invoice;
  final String currency;
  final List<InvoiceItem>? items;
  final VoidCallback onExpand;

  const _InvoiceCard({
    required this.invoice,
    required this.currency,
    required this.items,
    required this.onExpand,
  });

  @override
  State<_InvoiceCard> createState() => _InvoiceCardState();
}

class _InvoiceCardState extends State<_InvoiceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy  hh:mm a').format(widget.invoice.createdAt);
    final shortId = widget.invoice.id.length > 8
        ? '...${widget.invoice.id.substring(widget.invoice.id.length - 8)}'
        : widget.invoice.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (!_expanded && widget.items == null) {
                widget.onExpand();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(shortId,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${widget.currency}${widget.invoice.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(12)),
              ),
              child: widget.items == null
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()))
                  : widget.items!.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No items',
                              style: TextStyle(color: Colors.grey)))
                      : Column(
                          children: widget.items!.map((item) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.productName}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    '${widget.currency}${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
            ),
        ],
      ),
    );
  }
}
