import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';

part 'shop_event.dart';
part 'shop_state.dart';

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  final ShopRepository repository;

  ShopBloc({required this.repository}) : super(ShopInitial()) {
    on<LoadShopEvent>(_onLoadShop);
    on<UpdateShopEvent>(_onUpdateShop);
  }

  Future<void> _onLoadShop(LoadShopEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());
    final result = await repository.getShop();
    result.fold(
      (failure) => emit(const ShopError(ShopFailure.loadFailed)),
      (shop) => emit(ShopLoaded(shop)),
    );
  }

  Future<void> _onUpdateShop(
      UpdateShopEvent event, Emitter<ShopState> emit) async {
    emit(ShopLoading());
    final result = await repository.updateShop(event.shop);
    result.fold(
      (failure) => emit(const ShopError(ShopFailure.saveFailed)),
      (_) {
        // Reload shop to update state with latest data (though local is same)
        add(LoadShopEvent());
        emit(ShopOperationSuccess());
      },
    );
  }
}
