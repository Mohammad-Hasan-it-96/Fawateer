part of 'attribute_definition_bloc.dart';

enum AttributeDefStatus { initial, loading, loaded, error }

/// One-shot result of an option rename/delete, so the page can say **how many
/// products moved**. Typed, not a string — no user-facing English in a BLoC.
enum OptionChangeKind { renamed, removed }

class OptionChangeOutcome extends Equatable {
  final OptionChangeKind kind;
  final int productsAffected;
  const OptionChangeOutcome(this.kind, this.productsAffected);

  @override
  List<Object?> get props => [kind, productsAffected];
}

class AttributeDefinitionState extends Equatable {
  final AttributeDefStatus status;
  final List<AttributeDefinition> definitions;

  /// Transient — cleared on the next emit, like every other one-shot in this
  /// app, so it can't re-fire a snackbar.
  final OptionChangeOutcome? optionChange;

  const AttributeDefinitionState({
    this.status = AttributeDefStatus.initial,
    this.definitions = const [],
    this.optionChange,
  });

  /// Non-archived definitions in display order — what forms/lists render.
  List<AttributeDefinition> get active =>
      definitions.where((d) => !d.isArchived).toList();

  AttributeDefinitionState copyWith({
    AttributeDefStatus? status,
    List<AttributeDefinition>? definitions,
    OptionChangeOutcome? optionChange,
  }) {
    return AttributeDefinitionState(
      status: status ?? this.status,
      definitions: definitions ?? this.definitions,
      optionChange: optionChange,
    );
  }

  @override
  List<Object?> get props => [status, definitions, optionChange];
}
