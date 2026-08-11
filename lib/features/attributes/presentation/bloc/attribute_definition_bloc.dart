import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/attribute_definition.dart';
import '../../domain/repositories/attribute_definition_repository.dart';

part 'attribute_definition_event.dart';
part 'attribute_definition_state.dart';

/// App-wide, stream-backed manager for the owner's custom product fields
/// (Plan 010). Loaded once at startup ([LoadDefinitions]); the add/edit product
/// form and the Settings → Product Fields page both read [state.active].
class AttributeDefinitionBloc
    extends Bloc<AttributeDefinitionEvent, AttributeDefinitionState> {
  final AttributeDefinitionRepository repository;

  bool _watching = false;

  AttributeDefinitionBloc({required this.repository})
      : super(const AttributeDefinitionState()) {
    on<LoadDefinitions>(_onLoad);
    on<SaveDefinition>(_onSave);
    on<DeleteDefinition>(_onDelete);
    on<ApplyTemplate>(_onApplyTemplate);
    on<RenameOption>(_onRenameOption);
    on<RemoveOption>(_onRemoveOption);
  }

  Future<void> _onRenameOption(
      RenameOption event, Emitter<AttributeDefinitionState> emit) async {
    final result = await repository.renameOption(
      definitionId: event.definitionId,
      from: event.from,
      to: event.to,
    );
    result.fold(
      (_) => emit(state.copyWith(status: AttributeDefStatus.error)),
      (moved) => emit(state.copyWith(
        status: AttributeDefStatus.loaded,
        optionChange: OptionChangeOutcome(OptionChangeKind.renamed, moved),
      )),
    );
  }

  Future<void> _onRemoveOption(
      RemoveOption event, Emitter<AttributeDefinitionState> emit) async {
    final result = await repository.removeOption(
      definitionId: event.definitionId,
      value: event.value,
    );
    result.fold(
      (_) => emit(state.copyWith(status: AttributeDefStatus.error)),
      (cleared) => emit(state.copyWith(
        status: AttributeDefStatus.loaded,
        optionChange: OptionChangeOutcome(OptionChangeKind.removed, cleared),
      )),
    );
  }

  Future<void> _onLoad(
      LoadDefinitions event, Emitter<AttributeDefinitionState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: AttributeDefStatus.loading));
    await emit.forEach(
      repository.watchDefinitions(),
      onData: (defs) =>
          state.copyWith(status: AttributeDefStatus.loaded, definitions: defs),
      onError: (_, __) => state.copyWith(status: AttributeDefStatus.error),
    );
  }

  Future<void> _onSave(
      SaveDefinition event, Emitter<AttributeDefinitionState> emit) async {
    final result = await repository.save(event.definition);
    result.fold(
      (_) => emit(state.copyWith(status: AttributeDefStatus.error)),
      (_) => emit(state.copyWith(status: AttributeDefStatus.loaded)),
    );
  }

  Future<void> _onDelete(
      DeleteDefinition event, Emitter<AttributeDefinitionState> emit) async {
    final result = await repository.delete(event.id);
    result.fold(
      (_) => emit(state.copyWith(status: AttributeDefStatus.error)),
      (_) => emit(state.copyWith(status: AttributeDefStatus.loaded)),
    );
  }

  Future<void> _onApplyTemplate(
      ApplyTemplate event, Emitter<AttributeDefinitionState> emit) async {
    if (event.definitions.isEmpty) return; // "General" seeds nothing
    final result = await repository.saveAll(event.definitions);
    result.fold(
      (_) => emit(state.copyWith(status: AttributeDefStatus.error)),
      (_) => emit(state.copyWith(status: AttributeDefStatus.loaded)),
    );
  }
}
