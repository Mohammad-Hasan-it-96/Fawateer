import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/customer.dart';
import '../bloc/customer_bloc.dart';

/// Add (customer == null) or edit an existing customer.
class AddEditCustomerPage extends StatefulWidget {
  final Customer? customer;
  const AddEditCustomerPage({super.key, this.customer});

  @override
  State<AddEditCustomerPage> createState() => _AddEditCustomerPageState();
}

class _AddEditCustomerPageState extends State<AddEditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _phone = TextEditingController(text: widget.customer?.phone ?? '');
    _note = TextEditingController(text: widget.customer?.note ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  /// True if another (non-current) customer already has this name, compared
  /// case-insensitively and trimmed against the live [CustomerBloc] list.
  bool _isDuplicateName(String value) {
    final needle = value.trim().toLowerCase();
    return context.read<CustomerBloc>().state.customers.any((acc) =>
        acc.customer.id != widget.customer?.id &&
        acc.customer.name.trim().toLowerCase() == needle);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<CustomerBloc>();
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final note = _note.text.trim();

    if (_isEdit) {
      bloc.add(UpdateCustomer(
          widget.customer!.copyWith(name: name, phone: phone, note: note)));
    } else {
      bloc.add(AddCustomer(Customer(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
        note: note,
        createdAt: DateTime.now(),
      )));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? l10n.editCustomer : l10n.addCustomer,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.customerPhoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.customerNoteLabel,
                prefixIcon: const Icon(Icons.notes),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),
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
