import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/bulk_price_edit.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../settings/domain/repositories/printer_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  final PrinterRepository printerRepository;

  /// Guards against a second [LoadProducts] spinning up a duplicate stream
  /// subscription (and duplicate emits).
  bool _watching = false;

  ProductBloc({required this.repository, required this.printerRepository})
      : super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>((e, emit) => _runMutation(
        emit, () => repository.addProduct(e.product), ProductMessage.added));
    on<UpdateProduct>((e, emit) => _runMutation(emit,
        () => repository.updateProduct(e.product), ProductMessage.updated));
    on<DeleteProduct>((e, emit) => _runMutation(
        emit, () => repository.deleteProduct(e.id), ProductMessage.deleted));
    on<PrintProductLabel>(_onPrintLabel);
    on<BulkUpdatePrices>(_onBulkUpdatePrices);
  }

  /// Apply one price/cost change across a selection (Plan 015 B2.2).
  ///
  /// Only the products the edit actually moves are written. That is not just an
  /// optimisation: on the sync branch every touched row gets a fresh HLC stamp
  /// and is pushed, so re-writing 200 unchanged prices would be 200 pointless
  /// rows over the wire.
  Future<void> _onBulkUpdatePrices(
      BulkUpdatePrices event, Emitter<ProductState> emit) async {
    final updated = [
      for (final p in state.products)
        if (event.productIds.contains(p.id) && event.edit.changes(p))
          event.edit.applyTo(p),
    ];
    if (updated.isEmpty) {
      emit(state.copyWith(
          status: ProductStatus.success,
          message: ProductMessage.bulkPricesUnchanged));
      return;
    }
    final result = await repository.updatePrices(updated);
    result.fold(
      (_) => emit(state.copyWith(
          status: ProductStatus.error, message: ProductMessage.saveFailed)),
      (_) => emit(state.copyWith(
        status: ProductStatus.success,
        message: ProductMessage.bulkPricesUpdated,
        messageCount: updated.length,
      )),
    );
  }

  /// Print product label(s) via the printer (best-effort, like a receipt).
  /// Emits a transient success/failure message the page maps to a snackbar.
  Future<void> _onPrintLabel(
      PrintProductLabel event, Emitter<ProductState> emit) async {
    final ok = await printerRepository.printLabel(
      name: event.name,
      priceText: event.priceText,
      barcodeData: event.barcodeData,
      useQr: event.useQr,
      copies: event.copies,
    );
    emit(state.copyWith(
      status: ok ? ProductStatus.success : ProductStatus.error,
      message:
          ok ? ProductMessage.labelPrinted : ProductMessage.labelPrintFailed,
    ));
  }

  /// Subscribe to the product stream. Dispatched once at startup; the list then
  /// stays live — add/update/delete and stock changes from a sale all flow in
  /// automatically, so mutation handlers don't re-fetch.
  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    if (_watching) return;
    _watching = true;
    emit(state.copyWith(status: ProductStatus.loading));
    // A transient stream error emits an error state but keeps the subscription
    // alive (`emit.forEach` doesn't cancel on error), so the list self-recovers
    // on the next emission.
    await emit.forEach(
      repository.watchProducts(),
      onData: (products) =>
          state.copyWith(status: ProductStatus.loaded, products: products),
      onError: (e, _) => state.copyWith(
          status: ProductStatus.error, message: ProductMessage.loadFailed),
    );
  }

  /// Run a create/update/delete and emit success or a mapped error. The list
  /// itself refreshes from the stream, so there's nothing to re-fetch here.
  Future<void> _runMutation(
    Emitter<ProductState> emit,
    Future<Either<Failure, void>> Function() action,
    ProductMessage successMessage,
  ) async {
    final result = await action();
    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductStatus.error,
        message: failure is DuplicateFailure
            ? ProductMessage.barcodeExists
            : ProductMessage.saveFailed,
      )),
      (_) => emit(state.copyWith(
          status: ProductStatus.success, message: successMessage)),
    );
  }
}
