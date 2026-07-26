import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_snack.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_unit.dart';
import '../../domain/entities/unit_status.dart';
import '../bloc/product_unit_bloc.dart';

/// Serialized units for one SKU (Plan 012) — the shop's list of physical
/// handsets: add them as they arrive, see which are still on the shelf, and
/// answer "which invoice sold this IMEI, and is it under warranty?".
class ProductUnitsPage extends StatefulWidget {
  final Product product;
  const ProductUnitsPage({super.key, required this.product});

  @override
  State<ProductUnitsPage> createState() => _ProductUnitsPageState();
}

class _ProductUnitsPageState extends State<ProductUnitsPage> {
  /// Free-text filter over serials — the warranty-lookup path when a customer
  /// walks in with a handset. Kept local: it's view state, not domain state.
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.unitsTitle(widget.product.name))),
      body: BlocConsumer<ProductUnitBloc, ProductUnitState>(
        listenWhen: (p, c) => p.message != c.message && c.message != null,
        listener: (context, state) {
          final (text, ok) = _messageText(state.message!, l10n);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(text),
              backgroundColor: ok ? null : Colors.red,
              duration: AppSnackDuration.brief,
            ));
          context.read<ProductUnitBloc>().add(const ClearUnitMessage());
        },
        builder: (context, state) {
          if (state.loading && state.units.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final q = _search.trim().toLowerCase();
          final visible = q.isEmpty
              ? state.units
              : state.units
                  .where((u) => u.serial.toLowerCase().contains(q))
                  .toList();

          return Column(
            children: [
              _summary(context, l10n, state),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.unitsSearchHint,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              if (visible.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.units.isEmpty
                            ? l10n.unitsEmpty
                            : l10n.unitsNoMatch,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _unitTile(context, l10n, visible[i]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addUnit(context, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.unitsAdd),
      ),
    );
  }

  Widget _summary(
      BuildContext context, AppLocalizations l10n, ProductUnitState state) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.inventory_2_outlined, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.unitsSummary(state.availableCount, state.units.length),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitTile(
      BuildContext context, AppLocalizations l10n, ProductUnit unit) {
    final scheme = Theme.of(context).colorScheme;
    final df = DateFormat('yyyy/MM/dd');
    final warrantyLive = unit.warrantyUntil != null &&
        unit.isUnderWarrantyAt(DateTime.now());

    return ListTile(
      title: Text(
        unit.serial.isEmpty ? l10n.unitsNoSerial : unit.serial,
        style: TextStyle(
          fontFamily: 'monospace',
          fontStyle: unit.serial.isEmpty ? FontStyle.italic : null,
        ),
      ),
      subtitle: Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _statusChip(context, l10n, unit.status),
          if (unit.warrantyUntil != null)
            Text(
              l10n.unitsWarrantyUntil(df.format(unit.warrantyUntil!)),
              style: TextStyle(
                fontSize: 12,
                // Green while the shop still owes a repair, grey once it
                // doesn't — the one fact a customer at the counter is asking
                // about, so it should be readable at a glance.
                color: warrantyLive ? Colors.green.shade700 : scheme.outline,
              ),
            ),
          if (unit.soldAt != null)
            Text(l10n.unitsSoldOn(df.format(unit.soldAt!)),
                style: TextStyle(fontSize: 12, color: scheme.outline)),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) => switch (v) {
          'warranty' => _setWarranty(context, l10n, unit),
          'defective' => context
              .read<ProductUnitBloc>()
              .add(SetUnitStatus(unit.id, UnitStatus.defective)),
          'restock' => context
              .read<ProductUnitBloc>()
              .add(SetUnitStatus(unit.id, UnitStatus.inStock)),
          'delete' => _confirmDelete(context, l10n, unit),
          _ => null,
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'warranty', child: Text(l10n.unitsSetWarranty)),
          if (unit.status == UnitStatus.inStock)
            PopupMenuItem(
                value: 'defective', child: Text(l10n.unitsMarkDefective)),
          if (unit.status == UnitStatus.defective ||
              unit.status == UnitStatus.returned)
            PopupMenuItem(value: 'restock', child: Text(l10n.unitsRestock)),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }

  Widget _statusChip(
      BuildContext context, AppLocalizations l10n, UnitStatus status) {
    final (label, color) = switch (status) {
      UnitStatus.inStock => (l10n.unitStatusInStock, Colors.green),
      UnitStatus.sold => (l10n.unitStatusSold, Colors.blueGrey),
      UnitStatus.returned => (l10n.unitStatusReturned, Colors.orange),
      UnitStatus.defective => (l10n.unitStatusDefective, Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _addUnit(BuildContext context, AppLocalizations l10n) async {
    final bloc = context.read<ProductUnitBloc>();
    final controller = TextEditingController();

    final serial = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unitsAdd),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.unitsSerialLabel,
                  hintText: l10n.unitsSerialHint,
                ),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
            ),
            // Scanning beats typing a 15-digit IMEI by hand — and it is the
            // same code path the POS uses to find the unit later, so a scanned
            // serial is guaranteed to match.
            IconButton(
              tooltip: l10n.scanBarcodeTitle,
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final code = await ctx.push<String>('/scanner');
                if (code != null) controller.text = code;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );

    if (serial == null) return;
    bloc.add(AddUnit(ProductUnit(
      id: const Uuid().v4(),
      productId: widget.product.id,
      serial: serial.trim(),
      createdAt: DateTime.now(),
    )));
  }

  Future<void> _setWarranty(
      BuildContext context, AppLocalizations l10n, ProductUnit unit) async {
    final bloc = context.read<ProductUnitBloc>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: unit.warrantyUntil ?? DateTime(now.year + 1, now.month, now.day),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;
    bloc.add(SetUnitWarranty(unit.id, picked));
  }

  Future<void> _confirmDelete(
      BuildContext context, AppLocalizations l10n, ProductUnit unit) async {
    final bloc = context.read<ProductUnitBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.unitsDeleteTitle),
        content: Text(l10n.unitsDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok == true) bloc.add(DeleteUnit(unit.id));
  }

  (String, bool) _messageText(UnitMessage m, AppLocalizations l10n) =>
      switch (m) {
        UnitMessage.added => (l10n.unitsAdded, true),
        UnitMessage.saved => (l10n.unitsSaved, true),
        UnitMessage.deleted => (l10n.unitsDeleted, true),
        UnitMessage.loadFailed => (l10n.unitsLoadFailed, false),
        UnitMessage.saveFailed => (l10n.unitsSaveFailed, false),
        UnitMessage.duplicateSerial => (l10n.unitsDuplicateSerial, false),
        UnitMessage.deleteBlockedSold => (l10n.unitsDeleteBlockedSold, false),
      };
}
