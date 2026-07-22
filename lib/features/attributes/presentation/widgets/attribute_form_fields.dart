import 'package:flutter/material.dart';

import '../../../../core/utils/num_input.dart';
import '../../../../core/widgets/input_label.dart';
import '../../domain/entities/attribute_definition.dart';
import '../../domain/entities/attribute_type.dart';

/// Renders the owner's custom product fields (Plan 010) inside an existing
/// [Form], seeded from [initialValues] and reporting edits through [onChanged]
/// as a `{definitionId: value}` map. Text/number/select fields participate in
/// the parent form's validation (required check); boolean/date manage their own.
///
/// Kept deliberately simple — every value is a display **string**; the field
/// [AttributeType] only chooses the input widget.
class AttributeFormFields extends StatefulWidget {
  final List<AttributeDefinition> definitions;
  final Map<String, String> initialValues;
  final ValueChanged<Map<String, String>> onChanged;

  const AttributeFormFields({
    super.key,
    required this.definitions,
    required this.initialValues,
    required this.onChanged,
  });

  @override
  State<AttributeFormFields> createState() => _AttributeFormFieldsState();
}

class _AttributeFormFieldsState extends State<AttributeFormFields> {
  late final Map<String, String> _values;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _values = Map<String, String>.from(widget.initialValues);
    for (final def in widget.definitions) {
      if (def.type == AttributeType.text || def.type == AttributeType.number) {
        _controllers[def.id] =
            TextEditingController(text: _values[def.id] ?? '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _set(String id, String value) {
    if (value.trim().isEmpty) {
      _values.remove(id);
    } else {
      _values[id] = value.trim();
    }
    widget.onChanged(Map<String, String>.from(_values));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.definitions.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final def in widget.definitions) ...[
          const SizedBox(height: 24),
          _buildField(def),
        ],
      ],
    );
  }

  Widget _buildField(AttributeDefinition def) {
    final labelText = def.unit.isEmpty ? def.label : '${def.label} (${def.unit})';
    switch (def.type) {
      case AttributeType.boolean:
        final on = _values[def.id] == 'true';
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(def.label),
            value: on,
            onChanged: (v) => setState(() => _set(def.id, v ? 'true' : 'false')),
          ),
        );
      case AttributeType.date:
        return _DateField(
          label: labelText,
          value: _values[def.id],
          isRequired: def.isRequired,
          onChanged: (iso) => setState(() => _set(def.id, iso)),
        );
      case AttributeType.select:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputLabel(text: labelText),
            DropdownButtonFormField<String>(
              initialValue: def.options.contains(_values[def.id])
                  ? _values[def.id]
                  : null,
              isExpanded: true,
              items: [
                for (final opt in def.options)
                  DropdownMenuItem(value: opt, child: Text(opt)),
              ],
              validator: def.isRequired
                  ? (v) => (v == null || v.isEmpty) ? '' : null
                  : null,
              onChanged: (v) => _set(def.id, v ?? ''),
            ),
          ],
        );
      case AttributeType.number:
      case AttributeType.text:
        final isNum = def.type == AttributeType.number;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputLabel(text: labelText),
            TextFormField(
              controller: _controllers[def.id],
              keyboardType: isNum
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              inputFormatters: isNum ? NumInput.decimalFormatters : null,
              validator: def.isRequired
                  ? (v) => (v == null || v.trim().isEmpty) ? '' : null
                  : null,
              onChanged: (v) => _set(def.id, v),
            ),
          ],
        );
    }
  }
}

/// A tappable date field storing an ISO `yyyy-MM-dd` string.
class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final bool isRequired;
  final ValueChanged<String> onChanged;

  const _DateField({
    required this.label,
    required this.value,
    required this.isRequired,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputLabel(text: label),
        FormField<String>(
          initialValue: value,
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? '' : null
              : null,
          builder: (field) {
            return InkWell(
              onTap: () async {
                final now = DateTime(2000);
                DateTime initial = DateTime(2025);
                final parsed = DateTime.tryParse(value ?? '');
                if (parsed != null) initial = parsed;
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: now,
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final iso =
                      '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  field.didChange(iso);
                  onChanged(iso);
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: field.hasError ? '' : null,
                  suffixIcon: const Icon(Icons.calendar_today, size: 18),
                ),
                child: Text(
                  (value == null || value!.isEmpty) ? '—' : value!,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
