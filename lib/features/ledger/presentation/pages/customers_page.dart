import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/customer_search.dart';
import '../../domain/entities/customer_account.dart';
import '../bloc/customer_bloc.dart';
import '../ledger_money.dart';

/// Map a [CustomerMessage] to a localized string (success + error feedback).
String customerMessageText(CustomerMessage m, AppLocalizations l10n) {
  switch (m) {
    case CustomerMessage.added:
      return l10n.customerAdded;
    case CustomerMessage.updated:
      return l10n.customerUpdated;
    case CustomerMessage.deleted:
      return l10n.customerDeleted;
    case CustomerMessage.deleteBlocked:
      return l10n.customerDeleteBlocked;
    case CustomerMessage.duplicateName:
      return l10n.duplicateCustomerName;
    case CustomerMessage.saveFailed:
      return l10n.customerSaveFailed;
    case CustomerMessage.loadFailed:
      return l10n.customersLoadFailed;
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  /// Search text (Plan 013 #2). Held in the page, not the BLoC: it is view
  /// state, the list is already in memory from `CustomerBloc`'s stream, and a
  /// shop's contact list is small enough to filter in Dart — the same call the
  /// product list makes.
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customersTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchCustomersHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/add'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add_alt),
        label: Text(l10n.addCustomer),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listenWhen: (prev, curr) => curr.message != null,
        listener: (context, state) {
          final isError = state.status == CustomerStatus.error;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(customerMessageText(state.message!, l10n)),
            backgroundColor: isError ? Colors.red : Colors.green,
          ));
        },
        builder: (context, state) {
          if (state.status == CustomerStatus.loading &&
              state.customers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.customers.isEmpty) {
            return _empty(context, l10n);
          }
          final visible = state.customers
              .where((c) => customerMatchesSearch(c, _query))
              .toList();
          // "No customers yet" and "no customer matches this search" are
          // different situations, and showing the first one to a shop with 200
          // customers reads as data loss.
          if (visible.isEmpty) return _noResults(context, l10n);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _customerTile(context, l10n, visible[i]),
          );
        },
      ),
    );
  }

  Widget _noResults(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.noCustomerResults,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.noCustomers,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(l10n.noCustomersHint,
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _customerTile(
      BuildContext context, AppLocalizations l10n, CustomerAccount acc) {
    final (label, color) = _balanceLabel(context, l10n, acc);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/customers/detail/${acc.customer.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  acc.customer.name.isNotEmpty
                      ? acc.customer.name.characters.first.toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(acc.customer.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (acc.customer.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(acc.customer.phone,
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (badge text, colour) for a customer's balance. Positive = owes the shop.
  (String, Color) _balanceLabel(
      BuildContext context, AppLocalizations l10n, CustomerAccount acc) {
    if (acc.isSettled) return (l10n.balanceSettled, Theme.of(context).colorScheme.onSurfaceVariant);
    final money = moneyText(context, acc.balance);
    if (acc.balance > 0) return (l10n.balanceOwed(money), Colors.red.shade600);
    return (l10n.balanceCredit(money), Colors.green.shade600);
  }
}
