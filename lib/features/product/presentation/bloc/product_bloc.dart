import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(const ProductState()) {
    on<LoadProducts>(_onLoadProducts);
    on<AddProduct>(_onAddProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  /// Subscribe to the product stream. Dispatched once at startup; the list then
  /// stays live — add/update/delete and stock changes from a sale all flow in
  /// automatically, so mutation handlers don't re-fetch. Stream emissions clear
  /// the transient action message so a later update can't re-trigger a snackbar.
  Future<void> _onLoadProducts(
      LoadProducts event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    await emit.forEach(
      repository.watchProducts(),
      onData: (products) =>
          state.copyWith(status: ProductStatus.loaded, products: products),
      onError: (e, _) =>
          state.copyWith(status: ProductStatus.error, message: e.toString()),
    );
  }

  Future<void> _onAddProduct(
      AddProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading)); // Keep products
    final result = await repository.addProduct(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product added successfully'));
      },
    );
  }

  Future<void> _onUpdateProduct(
      UpdateProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await repository.updateProduct(event.product);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product updated successfully'));
      },
    );
  }

  Future<void> _onDeleteProduct(
      DeleteProduct event, Emitter<ProductState> emit) async {
    emit(state.copyWith(status: ProductStatus.loading));
    final result = await repository.deleteProduct(event.id);
    result.fold(
      (failure) => emit(state.copyWith(
          status: ProductStatus.error, message: failure.message)),
      (_) {
        emit(state.copyWith(
            status: ProductStatus.success,
            message: 'Product deleted successfully'));
      },
    );
  }
}
