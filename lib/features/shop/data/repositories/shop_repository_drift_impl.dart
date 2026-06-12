import 'package:drift/drift.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/shop_dao.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/shop.dart';
import '../../domain/repositories/shop_repository.dart';

class ShopRepositoryDriftImpl implements ShopRepository {
  final ShopDao _dao;

  const ShopRepositoryDriftImpl(this._dao);

  static const Shop _defaultShop = Shop(
    name: 'My Shop',
    addressLine1: '',
    addressLine2: '',
    phoneNumber: '',
    footerText: 'Thank you, Visit again!',
    currencySymbol: '₹',
  );

  static Shop _rowToEntity(ShopRow row) => Shop(
        name: row.name,
        addressLine1: row.addressLine1,
        addressLine2: row.addressLine2,
        phoneNumber: row.phoneNumber,
        footerText: row.footerText,
        currencySymbol: row.currencySymbol,
      );

  @override
  Future<Either<Failure, Shop>> getShop() async {
    try {
      final row = await _dao.getShop();
      return Right(row != null ? _rowToEntity(row) : _defaultShop);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShop(Shop shop) async {
    try {
      await _dao.upsertShop(ShopSettingsCompanion(
        id: const Value('default'),
        name: Value(shop.name),
        addressLine1: Value(shop.addressLine1),
        addressLine2: Value(shop.addressLine2),
        phoneNumber: Value(shop.phoneNumber),
        upiId: const Value(''), // column kept in DB, unused in domain
        footerText: Value(shop.footerText),
        currencySymbol: Value(shop.currencySymbol),
      ));
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
