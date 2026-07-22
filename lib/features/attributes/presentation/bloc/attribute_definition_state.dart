part of 'attribute_definition_bloc.dart';

enum AttributeDefStatus { initial, loading, loaded, error }

class AttributeDefinitionState extends Equatable {
  final AttributeDefStatus status;
  final List<AttributeDefinition> definitions;

  const AttributeDefinitionState({
    this.status = AttributeDefStatus.initial,
    this.definitions = const [],
  });

  /// Non-archived definitions in display order — what forms/lists render.
  List<AttributeDefinition> get active =>
      definitions.where((d) => !d.isArchived).toList();

  AttributeDefinitionState copyWith({
    AttributeDefStatus? status,
    List<AttributeDefinition>? definitions,
  }) {
    return AttributeDefinitionState(
      status: status ?? this.status,
      definitions: definitions ?? this.definitions,
    );
  }

  @override
  List<Object?> get props => [status, definitions];
}
