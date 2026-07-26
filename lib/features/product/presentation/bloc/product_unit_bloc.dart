import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/product_unit.dart';
import '../../domain/entities/unit_status.dart';
import '../../domain/repositories/product_unit_repository.dart';

part 'product_unit_event.dart';
part 'product_unit_state.dart';

/// Serialized inventory for one SKU (Plan 012). Route-scoped to the units page,
/// like `LedgerBloc` is to a customer — a shop only looks at one product's
/// handsets at a time, so there's nothing to keep app-wide.
class ProductUnitBloc extends Bloc<ProductUnitEvent, ProductUnitState> {
  final ProductUnitRepository repository;

  bool _watching = false;

  ProductUnitBloc({required this.repository})
      : super(const ProductUnitState()) {
    on<LoadUnits>(_onLoad);
    on<AddUnit>(_onAdd);
    on<DeleteUnit>(_onDelete);
    on<SetUnitWarranty>(_onSetWarranty);
    on<SetUnitStatus>(_onSetStatus);
    on<ClearUnitMessage>(
        (event, emit) => emit(state.copyWith(clearMessage: true)));
  }

  Future<void> _onLoad(LoadUnits event, Emitter<ProductUnitState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(loading: true, productId: event.productId));
    await emit.forEach(
      repository.watchUnits(event.productId),
      onData: (units) => state.copyWith(loading: false, units: units),
      onError: (_, __) =>
          state.copyWith(loading: false, message: UnitMessage.loadFailed),
    );
  }

  Future<void> _onAdd(AddUnit event, Emitter<ProductUnitState> emit) async {
    final result = await repository.addUnit(event.unit);
    emit(result.match(
      (f) => state.copyWith(
        // A duplicate serial is the expected, actionable case — the cashier
        // typed or scanned an IMEI the shop already holds — so it gets its own
        // message rather than a generic failure.
        message: f is DuplicateFailure
            ? UnitMessage.duplicateSerial
            : UnitMessage.saveFailed,
      ),
      (_) => state.copyWith(message: UnitMessage.added),
    ));
  }

  Future<void> _onDelete(
      DeleteUnit event, Emitter<ProductUnitState> emit) async {
    final result = await repository.deleteUnit(event.id);
    emit(result.match(
      (f) => state.copyWith(
        // Refusing to delete a sold unit is a deliberate guard, not an error:
        // that row is the serial → invoice link a warranty claim depends on.
        message: f is ConflictFailure
            ? UnitMessage.deleteBlockedSold
            : UnitMessage.saveFailed,
      ),
      (_) => state.copyWith(message: UnitMessage.deleted),
    ));
  }

  Future<void> _onSetWarranty(
      SetUnitWarranty event, Emitter<ProductUnitState> emit) async {
    final result = await repository.setWarranty(event.id, event.until);
    emit(result.match(
      (_) => state.copyWith(message: UnitMessage.saveFailed),
      (_) => state.copyWith(message: UnitMessage.saved),
    ));
  }

  Future<void> _onSetStatus(
      SetUnitStatus event, Emitter<ProductUnitState> emit) async {
    final result = await repository.setStatus(event.id, event.status);
    emit(result.match(
      (_) => state.copyWith(message: UnitMessage.saveFailed),
      (_) => state.copyWith(message: UnitMessage.saved),
    ));
  }
}
