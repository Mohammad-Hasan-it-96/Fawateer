part of 'product_unit_bloc.dart';

abstract class ProductUnitEvent extends Equatable {
  const ProductUnitEvent();
  @override
  List<Object?> get props => [];
}

/// Subscribe to one SKU's units. Dispatched once by the page.
class LoadUnits extends ProductUnitEvent {
  final String productId;
  const LoadUnits(this.productId);
  @override
  List<Object?> get props => [productId];
}

class AddUnit extends ProductUnitEvent {
  final ProductUnit unit;
  const AddUnit(this.unit);
  @override
  List<Object?> get props => [unit];
}

class DeleteUnit extends ProductUnitEvent {
  final String id;
  const DeleteUnit(this.id);
  @override
  List<Object?> get props => [id];
}

/// Set or clear (null) a unit's warranty expiry.
class SetUnitWarranty extends ProductUnitEvent {
  final String id;
  final DateTime? until;
  const SetUnitWarranty(this.id, this.until);
  @override
  List<Object?> get props => [id, until];
}

class SetUnitStatus extends ProductUnitEvent {
  final String id;
  final UnitStatus status;
  const SetUnitStatus(this.id, this.status);
  @override
  List<Object?> get props => [id, status];
}

/// Clears the one-shot [ProductUnitState.message] once the page has shown it.
class ClearUnitMessage extends ProductUnitEvent {
  const ClearUnitMessage();
}
