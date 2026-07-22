import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/business_templates.dart';
import '../../domain/entities/attribute_definition.dart';
import '../../domain/entities/attribute_type.dart';
import '../bloc/attribute_definition_bloc.dart';

/// Settings → Product fields (Plan 010). Lists the owner's custom fields and
/// lets them add/edit/archive/delete, or seed a business template.
class AttributeFieldsPage extends StatelessWidget {
  const AttributeFieldsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.productFieldsTitle),
        centerTitle: true,
      ),
      body: BlocBuilder<AttributeDefinitionBloc, AttributeDefinitionState>(
        builder: (context, state) {
          final defs = state.definitions; // includes archived
          if (defs.isEmpty) {
            return _EmptyState(l10n: l10n);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final def in defs) _DefinitionTile(definition: def),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openTemplatePicker(context),
                icon: const Icon(Icons.dashboard_customize_outlined),
                label: Text(l10n.useTemplateBtn),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, null),
        icon: const Icon(Icons.add),
        label: Text(l10n.addFieldBtn),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(l10n.productFieldsEmpty,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.productFieldsEmptyHint,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openTemplatePicker(context),
              icon: const Icon(Icons.dashboard_customize_outlined),
              label: Text(l10n.useTemplateBtn),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openEditor(context, null),
              icon: const Icon(Icons.add),
              label: Text(l10n.addFieldBtn),
            ),
          ],
        ),
      ),
    );
  }
}

class _DefinitionTile extends StatelessWidget {
  final AttributeDefinition definition;
  const _DefinitionTile({required this.definition});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitleBits = <String>[attributeTypeLabel(l10n, definition.type)];
    if (definition.unit.isNotEmpty) subtitleBits.add(definition.unit);
    if (definition.isRequired) subtitleBits.add(l10n.fieldRequiredLabel);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Row(
          children: [
            Flexible(child: Text(definition.label)),
            if (definition.isArchived) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l10n.fieldArchivedBadge,
                    style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ],
        ),
        subtitle: Text(subtitleBits.join(' · ')),
        onTap: () => _openEditor(context, definition),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            final bloc = context.read<AttributeDefinitionBloc>();
            switch (v) {
              case 'archive':
                bloc.add(SaveDefinition(
                    definition.copyWith(isArchived: !definition.isArchived)));
                break;
              case 'delete':
                bloc.add(DeleteDefinition(definition.id));
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
                value: 'archive',
                child: Text(definition.isArchived
                    ? l10n.fieldUnarchiveAction
                    : l10n.fieldArchiveAction)),
            PopupMenuItem(
                value: 'delete', child: Text(l10n.fieldDeleteAction)),
          ],
        ),
      ),
    );
  }
}

/// Localized name for an [AttributeType] (shared with any list subtitle).
String attributeTypeLabel(AppLocalizations l10n, AttributeType type) {
  switch (type) {
    case AttributeType.text:
      return l10n.attrTypeText;
    case AttributeType.number:
      return l10n.attrTypeNumber;
    case AttributeType.select:
      return l10n.attrTypeSelect;
    case AttributeType.boolean:
      return l10n.attrTypeBoolean;
    case AttributeType.date:
      return l10n.attrTypeDate;
  }
}

// ── template picker ──────────────────────────────────────────────────────────

void _openTemplatePicker(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).languageCode;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Text(l10n.chooseBusinessType,
                  style: Theme.of(sheetCtx).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l10n.templateSeedNote,
                  style: Theme.of(sheetCtx).textTheme.bodySmall),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final t in kBusinessTemplates)
                    ListTile(
                      leading: Text(t.emoji,
                          style: const TextStyle(fontSize: 24)),
                      title: Text(locale == 'ar' ? t.nameAr : t.nameEn),
                      subtitle: t.isEmpty
                          ? null
                          : Text(t.definitions.map((d) => d.label).join('، ')),
                      onTap: () {
                        context
                            .read<AttributeDefinitionBloc>()
                            .add(ApplyTemplate(t.definitions));
                        Navigator.of(sheetCtx).pop();
                        if (!t.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.templateAppliedMsg)),
                          );
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// ── definition editor ────────────────────────────────────────────────────────

void _openEditor(BuildContext context, AttributeDefinition? existing) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
      child: _DefinitionEditor(
        existing: existing,
        bloc: context.read<AttributeDefinitionBloc>(),
      ),
    ),
  );
}

class _DefinitionEditor extends StatefulWidget {
  final AttributeDefinition? existing;
  final AttributeDefinitionBloc bloc;
  const _DefinitionEditor({required this.existing, required this.bloc});

  @override
  State<_DefinitionEditor> createState() => _DefinitionEditorState();
}

class _DefinitionEditorState extends State<_DefinitionEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _unit;
  late final TextEditingController _options;
  late AttributeType _type;
  late bool _required;
  late bool _showInList;
  late bool _showOnReceipt;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _unit = TextEditingController(text: e?.unit ?? '');
    _options = TextEditingController(text: e?.options.join('، ') ?? '');
    _type = e?.type ?? AttributeType.text;
    _required = e?.isRequired ?? false;
    _showInList = e?.showInList ?? false;
    _showOnReceipt = e?.showOnReceipt ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _unit.dispose();
    _options.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final options = _type == AttributeType.select
        ? _options.text
            .split(RegExp(r'[,،]'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    final existing = widget.existing;
    // Next sort order (append) for a brand-new field.
    final maxOrder = widget.bloc.state.definitions
        .fold<int>(0, (m, d) => d.sortOrder > m ? d.sortOrder : m);
    final def = AttributeDefinition(
      id: existing?.id ?? const Uuid().v4(),
      label: _label.text.trim(),
      type: _type,
      options: options,
      unit: _unit.text.trim(),
      isRequired: _required,
      showInList: _showInList,
      showOnReceipt: _showOnReceipt,
      sortOrder: existing?.sortOrder ?? (maxOrder + 1),
      isArchived: existing?.isArchived ?? false,
    );
    widget.bloc.add(SaveDefinition(def));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _label,
              decoration: InputDecoration(
                labelText: l10n.fieldNameLabel,
                hintText: l10n.fieldNameHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AttributeType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.fieldTypeLabel),
              items: [
                for (final t in AttributeType.values)
                  DropdownMenuItem(
                      value: t, child: Text(attributeTypeLabel(l10n, t))),
              ],
              onChanged: (t) => setState(() => _type = t ?? AttributeType.text),
            ),
            if (_type == AttributeType.select) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _options,
                decoration: InputDecoration(
                  labelText: l10n.fieldOptionsLabel,
                  hintText: l10n.fieldOptionsHint,
                ),
                validator: (v) => _type == AttributeType.select &&
                        (v == null || v.trim().isEmpty)
                    ? l10n.fieldRequired
                    : null,
              ),
            ],
            if (_type == AttributeType.number) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _unit,
                decoration: InputDecoration(
                  labelText: l10n.fieldUnitLabel,
                  hintText: l10n.fieldUnitHint,
                ),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldRequiredLabel),
              value: _required,
              onChanged: (v) => setState(() => _required = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldShowInListLabel),
              value: _showInList,
              onChanged: (v) => setState(() => _showInList = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fieldShowOnReceiptLabel),
              value: _showOnReceipt,
              onChanged: (v) => setState(() => _showOnReceipt = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.saveChangesBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
