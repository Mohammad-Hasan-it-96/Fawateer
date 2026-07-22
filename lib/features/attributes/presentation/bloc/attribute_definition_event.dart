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

/// Seed a business template's fields in one shot (onboarding).
class ApplyTemplate extends AttributeDefinitionEvent {
  final List<AttributeDefinition> definitions;
  const ApplyTemplate(this.definitions);

  @override
  List<Object?> get props => [definitions];
}
