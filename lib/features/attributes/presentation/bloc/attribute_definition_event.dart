part of 'attribute_definition_bloc.dart';

abstract class AttributeDefinitionEvent extends Equatable {
  const AttributeDefinitionEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribe to the definitions stream (dispatched once at startup).
class LoadDefinitions extends AttributeDefinitionEvent {
  const LoadDefinitions();
}

/// Create or update one definition.
class SaveDefinition extends AttributeDefinitionEvent {
  final AttributeDefinition definition;
  const SaveDefinition(this.definition);

  @override
  List<Object?> get props => [definition];
}

/// Hard-delete one definition (UI soft-archives instead when it's in use).
class DeleteDefinition extends AttributeDefinitionEvent {
  final String id;
  const DeleteDefinition(this.id);

  @override
  List<Object?> get props => [id];
}

/// Rename one `select` option **and carry its products with it**
/// (Plan 014 step 3). The definition edit alone would leave every product
/// holding the old string, so they would quietly drop out of the category.
class RenameOption extends AttributeDefinitionEvent {
  final String definitionId;
  final String from;
  final String to;
  const RenameOption(
      {required this.definitionId, required this.from, required this.to});

  @override
  List<Object?> get props => [definitionId, from, to];
}

/// Delete one `select` option and clear it from the products that held it.
class RemoveOption extends AttributeDefinitionEvent {
  final String definitionId;
  final String value;
  const RemoveOption({required this.definitionId, required this.value});

  @override
  List<Object?> get props => [definitionId, value];
}

/// Seed a business template's fields in one shot (onboarding).
class ApplyTemplate extends AttributeDefinitionEvent {
  final List<AttributeDefinition> definitions;
  const ApplyTemplate(this.definitions);

  @override
  List<Object?> get props => [definitions];
}
