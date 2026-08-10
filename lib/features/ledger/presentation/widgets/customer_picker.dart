import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_account.dart';
import '../bloc/customer_bloc.dart';

/// Ask the cashier which customer a credit sale belongs to, with inline
/// quick-add. Returns the chosen [Customer], or null if the sheet was
/// dismissed.
///
/// Shared on purpose: checkout asks this when *booking* a sale on credit, and
/// the invoice detail page asks it when *correcting* how a sale was recorded
/// (Plan 016 C-a). It is the same question, and a shop with eighty customers
/// needs the same search box either way — so there is one picker, not two that
/// drift apart.
///
/// A customer created here is dispatched to [CustomerBloc] before it is
/// returned, so it exists on the account list the moment the caller uses it.
Future<Customer?> pickCustomer(BuildContext context) async {
  final result = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CustomerPickerSheet(),
  );
  if (!context.mounted) return null;
  if (identical(result, _kAddNewCustomer)) {
    // The form lives in a dedicated stateful sheet that owns its controllers,
    // so they're disposed by the framework only after the route is fully gone —
    // disposing them here (right after the await) would crash the
    // still-animating sheet as it rebuilds against disposed controllers.
    final created = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddCustomerSheet(),
    );
    if (created == null || !context.mounted) return null;
    context.read<CustomerBloc>().add(AddCustomer(created));
    return created;
  }
  if (result is CustomerAccount) return result.customer;
  return null;
}

/// Sentinel popped by [_CustomerPickerSheet] when the user taps "add new
/// customer" — distinguishes that intent from a picked [CustomerAccount] or a
/// plain dismiss (null) at the call site.
final Object _kAddNewCustomer = Object();

/// Customer picker sheet. Small lists (< 5) show in full; larger lists show a
/// search field plus the first 4, with typing filtering live across everyone.
/// Pops the chosen [CustomerAccount], or [_kAddNewCustomer] for the add tile.
class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  static const _previewCount = 4;
  static const _searchThreshold = 5;

  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      final q = _search.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final customers = context.watch<CustomerBloc>().state.customers;
    final showSearch = customers.length >= _searchThreshold;

    // Which rows to display: filtered matches when searching, else the first 4
    // (large list) or everything (small list).
    List<CustomerAccount> visible;
    var hiddenCount = 0;
    if (_query.isNotEmpty) {
      visible = customers
          .where((acc) =>
              acc.customer.name.toLowerCase().contains(_query) ||
              acc.customer.phone.toLowerCase().contains(_query))
          .toList();
    } else if (showSearch) {
      visible = customers.take(_previewCount).toList();
      hiddenCount = customers.length - visible.length;
    } else {
      visible = customers;
    }

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l10n.selectCustomer,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person_add_alt_1, color: Colors.white),
              ),
              title: Text(l10n.addNewCustomer,
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, _kAddNewCustomer),
            ),
            if (showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.searchCustomerHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            const Divider(height: 1),
            if (customers.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noCustomers, textAlign: TextAlign.center),
              )
            else if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noMatchingCustomers,
                    textAlign: TextAlign.center),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: visible.length,
                  itemBuilder: (_, i) {
                    final acc = visible[i];
                    return ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(acc.customer.name),
                      subtitle: acc.customer.phone.isEmpty
                          ? null
                          : Text(acc.customer.phone),
                      onTap: () => Navigator.pop(context, acc),
                    );
                  },
                ),
              ),
            if (hiddenCount > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(l10n.andMoreTypeToSearch(hiddenCount),
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Keyboard-aware quick-add customer form. Owns its controllers (disposed in
/// [dispose], i.e. after the sheet's exit animation completes) and pops the
/// created [Customer] on save so the caller can select it immediately.
class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();

  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// True if a customer already has this name (case-insensitive, trimmed),
  /// checked against the live [CustomerBloc] list.
  bool _isDuplicateName(String value) {
    final needle = value.trim().toLowerCase();
    return context.read<CustomerBloc>().state.customers.any(
        (acc) => acc.customer.name.trim().toLowerCase() == needle);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        id: const Uuid().v4(),
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(l10n.addNewCustomer,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.customerNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.fieldRequired;
                if (_isDuplicateName(v)) return l10n.duplicateCustomerName;
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: l10n.customerPhoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
