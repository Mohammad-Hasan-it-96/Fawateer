part of 'shop_bloc.dart';

/// A localizable shop error. The BLoC sets the case; the page maps it to a
/// translated string — no user-facing English lives in the BLoC.
enum ShopFailure { loadFailed, saveFailed }

abstract class ShopState extends Equatable {
  const ShopState();
  @override
  List<Object> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoading extends ShopState {}

class ShopLoaded extends ShopState {
  final Shop shop;
  const ShopLoaded(this.shop);
  @override
  List<Object> get props => [shop];
}

class ShopError extends ShopState {
  final ShopFailure failure;
  const ShopError(this.failure);
  @override
  List<Object> get props => [failure];
}

class ShopOperationSuccess extends ShopState {}
