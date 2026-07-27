// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products
    with TableInfo<$ProductsTable, ProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
      'cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minStockAlertMeta =
      const VerificationMeta('minStockAlert');
  @override
  late final GeneratedColumn<double> minStockAlert = GeneratedColumn<double>(
      'min_stock_alert', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _saleTypeMeta =
      const VerificationMeta('saleType');
  @override
  late final GeneratedColumn<String> saleType = GeneratedColumn<String>(
      'sale_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('piece'));
  static const VerificationMeta _priceCurrencyMeta =
      const VerificationMeta('priceCurrency');
  @override
  late final GeneratedColumn<String> priceCurrency = GeneratedColumn<String>(
      'price_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sp'));
  static const VerificationMeta _attributesMeta =
      const VerificationMeta('attributes');
  @override
  late final GeneratedColumn<String> attributes = GeneratedColumn<String>(
      'attributes', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isSerializedMeta =
      const VerificationMeta('isSerialized');
  @override
  late final GeneratedColumn<bool> isSerialized = GeneratedColumn<bool>(
      'is_serialized', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_serialized" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        barcode,
        price,
        cost,
        quantity,
        minStockAlert,
        saleType,
        priceCurrency,
        attributes,
        isSerialized
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(Insertable<ProductRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
          _costMeta, cost.isAcceptableOrUnknown(data['cost']!, _costMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    }
    if (data.containsKey('min_stock_alert')) {
      context.handle(
          _minStockAlertMeta,
          minStockAlert.isAcceptableOrUnknown(
              data['min_stock_alert']!, _minStockAlertMeta));
    }
    if (data.containsKey('sale_type')) {
      context.handle(_saleTypeMeta,
          saleType.isAcceptableOrUnknown(data['sale_type']!, _saleTypeMeta));
    }
    if (data.containsKey('price_currency')) {
      context.handle(
          _priceCurrencyMeta,
          priceCurrency.isAcceptableOrUnknown(
              data['price_currency']!, _priceCurrencyMeta));
    }
    if (data.containsKey('attributes')) {
      context.handle(
          _attributesMeta,
          attributes.isAcceptableOrUnknown(
              data['attributes']!, _attributesMeta));
    }
    if (data.containsKey('is_serialized')) {
      context.handle(
          _isSerializedMeta,
          isSerialized.isAcceptableOrUnknown(
              data['is_serialized']!, _isSerializedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      cost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      minStockAlert: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}min_stock_alert'])!,
      saleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_type'])!,
      priceCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_currency'])!,
      attributes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attributes'])!,
      isSerialized: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_serialized'])!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class ProductRow extends DataClass implements Insertable<ProductRow> {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final double cost;
  final double quantity;
  final double minStockAlert;
  final String saleType;
  final String priceCurrency;
  final String attributes;
  final bool isSerialized;
  const ProductRow(
      {required this.id,
      required this.name,
      required this.barcode,
      required this.price,
      required this.cost,
      required this.quantity,
      required this.minStockAlert,
      required this.saleType,
      required this.priceCurrency,
      required this.attributes,
      required this.isSerialized});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['barcode'] = Variable<String>(barcode);
    map['price'] = Variable<double>(price);
    map['cost'] = Variable<double>(cost);
    map['quantity'] = Variable<double>(quantity);
    map['min_stock_alert'] = Variable<double>(minStockAlert);
    map['sale_type'] = Variable<String>(saleType);
    map['price_currency'] = Variable<String>(priceCurrency);
    map['attributes'] = Variable<String>(attributes);
    map['is_serialized'] = Variable<bool>(isSerialized);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      barcode: Value(barcode),
      price: Value(price),
      cost: Value(cost),
      quantity: Value(quantity),
      minStockAlert: Value(minStockAlert),
      saleType: Value(saleType),
      priceCurrency: Value(priceCurrency),
      attributes: Value(attributes),
      isSerialized: Value(isSerialized),
    );
  }

  factory ProductRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      barcode: serializer.fromJson<String>(json['barcode']),
      price: serializer.fromJson<double>(json['price']),
      cost: serializer.fromJson<double>(json['cost']),
      quantity: serializer.fromJson<double>(json['quantity']),
      minStockAlert: serializer.fromJson<double>(json['minStockAlert']),
      saleType: serializer.fromJson<String>(json['saleType']),
      priceCurrency: serializer.fromJson<String>(json['priceCurrency']),
      attributes: serializer.fromJson<String>(json['attributes']),
      isSerialized: serializer.fromJson<bool>(json['isSerialized']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'barcode': serializer.toJson<String>(barcode),
      'price': serializer.toJson<double>(price),
      'cost': serializer.toJson<double>(cost),
      'quantity': serializer.toJson<double>(quantity),
      'minStockAlert': serializer.toJson<double>(minStockAlert),
      'saleType': serializer.toJson<String>(saleType),
      'priceCurrency': serializer.toJson<String>(priceCurrency),
      'attributes': serializer.toJson<String>(attributes),
      'isSerialized': serializer.toJson<bool>(isSerialized),
    };
  }

  ProductRow copyWith(
          {String? id,
          String? name,
          String? barcode,
          double? price,
          double? cost,
          double? quantity,
          double? minStockAlert,
          String? saleType,
          String? priceCurrency,
          String? attributes,
          bool? isSerialized}) =>
      ProductRow(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        quantity: quantity ?? this.quantity,
        minStockAlert: minStockAlert ?? this.minStockAlert,
        saleType: saleType ?? this.saleType,
        priceCurrency: priceCurrency ?? this.priceCurrency,
        attributes: attributes ?? this.attributes,
        isSerialized: isSerialized ?? this.isSerialized,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      price: data.price.present ? data.price.value : this.price,
      cost: data.cost.present ? data.cost.value : this.cost,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      minStockAlert: data.minStockAlert.present
          ? data.minStockAlert.value
          : this.minStockAlert,
      saleType: data.saleType.present ? data.saleType.value : this.saleType,
      priceCurrency: data.priceCurrency.present
          ? data.priceCurrency.value
          : this.priceCurrency,
      attributes:
          data.attributes.present ? data.attributes.value : this.attributes,
      isSerialized: data.isSerialized.present
          ? data.isSerialized.value
          : this.isSerialized,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('quantity: $quantity, ')
          ..write('minStockAlert: $minStockAlert, ')
          ..write('saleType: $saleType, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('attributes: $attributes, ')
          ..write('isSerialized: $isSerialized')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, barcode, price, cost, quantity,
      minStockAlert, saleType, priceCurrency, attributes, isSerialized);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.price == this.price &&
          other.cost == this.cost &&
          other.quantity == this.quantity &&
          other.minStockAlert == this.minStockAlert &&
          other.saleType == this.saleType &&
          other.priceCurrency == this.priceCurrency &&
          other.attributes == this.attributes &&
          other.isSerialized == this.isSerialized);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> barcode;
  final Value<double> price;
  final Value<double> cost;
  final Value<double> quantity;
  final Value<double> minStockAlert;
  final Value<String> saleType;
  final Value<String> priceCurrency;
  final Value<String> attributes;
  final Value<bool> isSerialized;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minStockAlert = const Value.absent(),
    this.saleType = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.attributes = const Value.absent(),
    this.isSerialized = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.barcode = const Value.absent(),
    required double price,
    this.cost = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minStockAlert = const Value.absent(),
    this.saleType = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.attributes = const Value.absent(),
    this.isSerialized = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        price = Value(price);
  static Insertable<ProductRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? barcode,
    Expression<double>? price,
    Expression<double>? cost,
    Expression<double>? quantity,
    Expression<double>? minStockAlert,
    Expression<String>? saleType,
    Expression<String>? priceCurrency,
    Expression<String>? attributes,
    Expression<bool>? isSerialized,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (quantity != null) 'quantity': quantity,
      if (minStockAlert != null) 'min_stock_alert': minStockAlert,
      if (saleType != null) 'sale_type': saleType,
      if (priceCurrency != null) 'price_currency': priceCurrency,
      if (attributes != null) 'attributes': attributes,
      if (isSerialized != null) 'is_serialized': isSerialized,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? barcode,
      Value<double>? price,
      Value<double>? cost,
      Value<double>? quantity,
      Value<double>? minStockAlert,
      Value<String>? saleType,
      Value<String>? priceCurrency,
      Value<String>? attributes,
      Value<bool>? isSerialized,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      saleType: saleType ?? this.saleType,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      attributes: attributes ?? this.attributes,
      isSerialized: isSerialized ?? this.isSerialized,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (minStockAlert.present) {
      map['min_stock_alert'] = Variable<double>(minStockAlert.value);
    }
    if (saleType.present) {
      map['sale_type'] = Variable<String>(saleType.value);
    }
    if (priceCurrency.present) {
      map['price_currency'] = Variable<String>(priceCurrency.value);
    }
    if (attributes.present) {
      map['attributes'] = Variable<String>(attributes.value);
    }
    if (isSerialized.present) {
      map['is_serialized'] = Variable<bool>(isSerialized.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('barcode: $barcode, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('quantity: $quantity, ')
          ..write('minStockAlert: $minStockAlert, ')
          ..write('saleType: $saleType, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('attributes: $attributes, ')
          ..write('isSerialized: $isSerialized, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShopSettingsTable extends ShopSettings
    with TableInfo<$ShopSettingsTable, ShopRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShopSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('default'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressLine1Meta =
      const VerificationMeta('addressLine1');
  @override
  late final GeneratedColumn<String> addressLine1 = GeneratedColumn<String>(
      'address_line1', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _addressLine2Meta =
      const VerificationMeta('addressLine2');
  @override
  late final GeneratedColumn<String> addressLine2 = GeneratedColumn<String>(
      'address_line2', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _phoneNumberMeta =
      const VerificationMeta('phoneNumber');
  @override
  late final GeneratedColumn<String> phoneNumber = GeneratedColumn<String>(
      'phone_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _footerTextMeta =
      const VerificationMeta('footerText');
  @override
  late final GeneratedColumn<String> footerText = GeneratedColumn<String>(
      'footer_text', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _currencySymbolMeta =
      const VerificationMeta('currencySymbol');
  @override
  late final GeneratedColumn<String> currencySymbol = GeneratedColumn<String>(
      'currency_symbol', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('ل.س'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        addressLine1,
        addressLine2,
        phoneNumber,
        footerText,
        currencySymbol
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shop_settings';
  @override
  VerificationContext validateIntegrity(Insertable<ShopRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('address_line1')) {
      context.handle(
          _addressLine1Meta,
          addressLine1.isAcceptableOrUnknown(
              data['address_line1']!, _addressLine1Meta));
    }
    if (data.containsKey('address_line2')) {
      context.handle(
          _addressLine2Meta,
          addressLine2.isAcceptableOrUnknown(
              data['address_line2']!, _addressLine2Meta));
    }
    if (data.containsKey('phone_number')) {
      context.handle(
          _phoneNumberMeta,
          phoneNumber.isAcceptableOrUnknown(
              data['phone_number']!, _phoneNumberMeta));
    }
    if (data.containsKey('footer_text')) {
      context.handle(
          _footerTextMeta,
          footerText.isAcceptableOrUnknown(
              data['footer_text']!, _footerTextMeta));
    }
    if (data.containsKey('currency_symbol')) {
      context.handle(
          _currencySymbolMeta,
          currencySymbol.isAcceptableOrUnknown(
              data['currency_symbol']!, _currencySymbolMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShopRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShopRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      addressLine1: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address_line1'])!,
      addressLine2: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address_line2'])!,
      phoneNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone_number'])!,
      footerText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}footer_text'])!,
      currencySymbol: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}currency_symbol'])!,
    );
  }

  @override
  $ShopSettingsTable createAlias(String alias) {
    return $ShopSettingsTable(attachedDatabase, alias);
  }
}

class ShopRow extends DataClass implements Insertable<ShopRow> {
  final String id;
  final String name;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;
  final String footerText;
  final String currencySymbol;
  const ShopRow(
      {required this.id,
      required this.name,
      required this.addressLine1,
      required this.addressLine2,
      required this.phoneNumber,
      required this.footerText,
      required this.currencySymbol});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address_line1'] = Variable<String>(addressLine1);
    map['address_line2'] = Variable<String>(addressLine2);
    map['phone_number'] = Variable<String>(phoneNumber);
    map['footer_text'] = Variable<String>(footerText);
    map['currency_symbol'] = Variable<String>(currencySymbol);
    return map;
  }

  ShopSettingsCompanion toCompanion(bool nullToAbsent) {
    return ShopSettingsCompanion(
      id: Value(id),
      name: Value(name),
      addressLine1: Value(addressLine1),
      addressLine2: Value(addressLine2),
      phoneNumber: Value(phoneNumber),
      footerText: Value(footerText),
      currencySymbol: Value(currencySymbol),
    );
  }

  factory ShopRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShopRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      addressLine1: serializer.fromJson<String>(json['addressLine1']),
      addressLine2: serializer.fromJson<String>(json['addressLine2']),
      phoneNumber: serializer.fromJson<String>(json['phoneNumber']),
      footerText: serializer.fromJson<String>(json['footerText']),
      currencySymbol: serializer.fromJson<String>(json['currencySymbol']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'addressLine1': serializer.toJson<String>(addressLine1),
      'addressLine2': serializer.toJson<String>(addressLine2),
      'phoneNumber': serializer.toJson<String>(phoneNumber),
      'footerText': serializer.toJson<String>(footerText),
      'currencySymbol': serializer.toJson<String>(currencySymbol),
    };
  }

  ShopRow copyWith(
          {String? id,
          String? name,
          String? addressLine1,
          String? addressLine2,
          String? phoneNumber,
          String? footerText,
          String? currencySymbol}) =>
      ShopRow(
        id: id ?? this.id,
        name: name ?? this.name,
        addressLine1: addressLine1 ?? this.addressLine1,
        addressLine2: addressLine2 ?? this.addressLine2,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        footerText: footerText ?? this.footerText,
        currencySymbol: currencySymbol ?? this.currencySymbol,
      );
  ShopRow copyWithCompanion(ShopSettingsCompanion data) {
    return ShopRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      addressLine1: data.addressLine1.present
          ? data.addressLine1.value
          : this.addressLine1,
      addressLine2: data.addressLine2.present
          ? data.addressLine2.value
          : this.addressLine2,
      phoneNumber:
          data.phoneNumber.present ? data.phoneNumber.value : this.phoneNumber,
      footerText:
          data.footerText.present ? data.footerText.value : this.footerText,
      currencySymbol: data.currencySymbol.present
          ? data.currencySymbol.value
          : this.currencySymbol,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShopRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('addressLine1: $addressLine1, ')
          ..write('addressLine2: $addressLine2, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('footerText: $footerText, ')
          ..write('currencySymbol: $currencySymbol')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, addressLine1, addressLine2,
      phoneNumber, footerText, currencySymbol);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShopRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.addressLine1 == this.addressLine1 &&
          other.addressLine2 == this.addressLine2 &&
          other.phoneNumber == this.phoneNumber &&
          other.footerText == this.footerText &&
          other.currencySymbol == this.currencySymbol);
}

class ShopSettingsCompanion extends UpdateCompanion<ShopRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> addressLine1;
  final Value<String> addressLine2;
  final Value<String> phoneNumber;
  final Value<String> footerText;
  final Value<String> currencySymbol;
  final Value<int> rowid;
  const ShopSettingsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.addressLine1 = const Value.absent(),
    this.addressLine2 = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.footerText = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShopSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.addressLine1 = const Value.absent(),
    this.addressLine2 = const Value.absent(),
    this.phoneNumber = const Value.absent(),
    this.footerText = const Value.absent(),
    this.currencySymbol = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<ShopRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? addressLine1,
    Expression<String>? addressLine2,
    Expression<String>? phoneNumber,
    Expression<String>? footerText,
    Expression<String>? currencySymbol,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (addressLine1 != null) 'address_line1': addressLine1,
      if (addressLine2 != null) 'address_line2': addressLine2,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (footerText != null) 'footer_text': footerText,
      if (currencySymbol != null) 'currency_symbol': currencySymbol,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShopSettingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? addressLine1,
      Value<String>? addressLine2,
      Value<String>? phoneNumber,
      Value<String>? footerText,
      Value<String>? currencySymbol,
      Value<int>? rowid}) {
    return ShopSettingsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      footerText: footerText ?? this.footerText,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (addressLine1.present) {
      map['address_line1'] = Variable<String>(addressLine1.value);
    }
    if (addressLine2.present) {
      map['address_line2'] = Variable<String>(addressLine2.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = Variable<String>(phoneNumber.value);
    }
    if (footerText.present) {
      map['footer_text'] = Variable<String>(footerText.value);
    }
    if (currencySymbol.present) {
      map['currency_symbol'] = Variable<String>(currencySymbol.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShopSettingsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('addressLine1: $addressLine1, ')
          ..write('addressLine2: $addressLine2, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('footerText: $footerText, ')
          ..write('currencySymbol: $currencySymbol, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory SettingRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) => SettingRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  SettingRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesInvoicesTable extends SalesInvoices
    with TableInfo<$SalesInvoicesTable, SalesInvoiceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesInvoicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _invoiceDiscountMeta =
      const VerificationMeta('invoiceDiscount');
  @override
  late final GeneratedColumn<double> invoiceDiscount = GeneratedColumn<double>(
      'invoice_discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, totalAmount, invoiceDiscount];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_invoices';
  @override
  VerificationContext validateIntegrity(Insertable<SalesInvoiceRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('invoice_discount')) {
      context.handle(
          _invoiceDiscountMeta,
          invoiceDiscount.isAcceptableOrUnknown(
              data['invoice_discount']!, _invoiceDiscountMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesInvoiceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesInvoiceRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      invoiceDiscount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}invoice_discount'])!,
    );
  }

  @override
  $SalesInvoicesTable createAlias(String alias) {
    return $SalesInvoicesTable(attachedDatabase, alias);
  }
}

class SalesInvoiceRow extends DataClass implements Insertable<SalesInvoiceRow> {
  final String id;

  /// Stored as milliseconds since epoch.
  final int createdAt;
  final double totalAmount;
  final double invoiceDiscount;
  const SalesInvoiceRow(
      {required this.id,
      required this.createdAt,
      required this.totalAmount,
      required this.invoiceDiscount});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['total_amount'] = Variable<double>(totalAmount);
    map['invoice_discount'] = Variable<double>(invoiceDiscount);
    return map;
  }

  SalesInvoicesCompanion toCompanion(bool nullToAbsent) {
    return SalesInvoicesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      totalAmount: Value(totalAmount),
      invoiceDiscount: Value(invoiceDiscount),
    );
  }

  factory SalesInvoiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesInvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      invoiceDiscount: serializer.fromJson<double>(json['invoiceDiscount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'invoiceDiscount': serializer.toJson<double>(invoiceDiscount),
    };
  }

  SalesInvoiceRow copyWith(
          {String? id,
          int? createdAt,
          double? totalAmount,
          double? invoiceDiscount}) =>
      SalesInvoiceRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        totalAmount: totalAmount ?? this.totalAmount,
        invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      );
  SalesInvoiceRow copyWithCompanion(SalesInvoicesCompanion data) {
    return SalesInvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      invoiceDiscount: data.invoiceDiscount.present
          ? data.invoiceDiscount.value
          : this.invoiceDiscount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoiceRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('invoiceDiscount: $invoiceDiscount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, totalAmount, invoiceDiscount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesInvoiceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.totalAmount == this.totalAmount &&
          other.invoiceDiscount == this.invoiceDiscount);
}

class SalesInvoicesCompanion extends UpdateCompanion<SalesInvoiceRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<double> totalAmount;
  final Value<double> invoiceDiscount;
  final Value<int> rowid;
  const SalesInvoicesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.invoiceDiscount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesInvoicesCompanion.insert({
    required String id,
    required int createdAt,
    required double totalAmount,
    this.invoiceDiscount = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        totalAmount = Value(totalAmount);
  static Insertable<SalesInvoiceRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<double>? totalAmount,
    Expression<double>? invoiceDiscount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (invoiceDiscount != null) 'invoice_discount': invoiceDiscount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesInvoicesCompanion copyWith(
      {Value<String>? id,
      Value<int>? createdAt,
      Value<double>? totalAmount,
      Value<double>? invoiceDiscount,
      Value<int>? rowid}) {
    return SalesInvoicesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      totalAmount: totalAmount ?? this.totalAmount,
      invoiceDiscount: invoiceDiscount ?? this.invoiceDiscount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (invoiceDiscount.present) {
      map['invoice_discount'] = Variable<double>(invoiceDiscount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoicesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('invoiceDiscount: $invoiceDiscount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesItemsTable extends SalesItems
    with TableInfo<$SalesItemsTable, SalesItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
      'price', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _costMeta = const VerificationMeta('cost');
  @override
  late final GeneratedColumn<double> cost = GeneratedColumn<double>(
      'cost', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _priceCurrencyMeta =
      const VerificationMeta('priceCurrency');
  @override
  late final GeneratedColumn<String> priceCurrency = GeneratedColumn<String>(
      'price_currency', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('sp'));
  static const VerificationMeta _fxRateMeta = const VerificationMeta('fxRate');
  @override
  late final GeneratedColumn<double> fxRate = GeneratedColumn<double>(
      'fx_rate', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _priceOriginalMeta =
      const VerificationMeta('priceOriginal');
  @override
  late final GeneratedColumn<double> priceOriginal = GeneratedColumn<double>(
      'price_original', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _attributesSnapshotMeta =
      const VerificationMeta('attributesSnapshot');
  @override
  late final GeneratedColumn<String> attributesSnapshot =
      GeneratedColumn<String>('attributes_snapshot', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _saleTypeMeta =
      const VerificationMeta('saleType');
  @override
  late final GeneratedColumn<String> saleType = GeneratedColumn<String>(
      'sale_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _serialSnapshotMeta =
      const VerificationMeta('serialSnapshot');
  @override
  late final GeneratedColumn<String> serialSnapshot = GeneratedColumn<String>(
      'serial_snapshot', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        invoiceId,
        productId,
        productName,
        price,
        cost,
        quantity,
        priceCurrency,
        fxRate,
        priceOriginal,
        discount,
        attributesSnapshot,
        saleType,
        serialSnapshot
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales_items';
  @override
  VerificationContext validateIntegrity(Insertable<SalesItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    } else if (isInserting) {
      context.missing(_invoiceIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('cost')) {
      context.handle(
          _costMeta, cost.isAcceptableOrUnknown(data['cost']!, _costMeta));
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('price_currency')) {
      context.handle(
          _priceCurrencyMeta,
          priceCurrency.isAcceptableOrUnknown(
              data['price_currency']!, _priceCurrencyMeta));
    }
    if (data.containsKey('fx_rate')) {
      context.handle(_fxRateMeta,
          fxRate.isAcceptableOrUnknown(data['fx_rate']!, _fxRateMeta));
    }
    if (data.containsKey('price_original')) {
      context.handle(
          _priceOriginalMeta,
          priceOriginal.isAcceptableOrUnknown(
              data['price_original']!, _priceOriginalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('attributes_snapshot')) {
      context.handle(
          _attributesSnapshotMeta,
          attributesSnapshot.isAcceptableOrUnknown(
              data['attributes_snapshot']!, _attributesSnapshotMeta));
    }
    if (data.containsKey('sale_type')) {
      context.handle(_saleTypeMeta,
          saleType.isAcceptableOrUnknown(data['sale_type']!, _saleTypeMeta));
    }
    if (data.containsKey('serial_snapshot')) {
      context.handle(
          _serialSnapshotMeta,
          serialSnapshot.isAcceptableOrUnknown(
              data['serial_snapshot']!, _serialSnapshotMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalesItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalesItemRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      price: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price'])!,
      cost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      priceCurrency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}price_currency'])!,
      fxRate: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}fx_rate'])!,
      priceOriginal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}price_original'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      attributesSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attributes_snapshot'])!,
      saleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_type'])!,
      serialSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}serial_snapshot'])!,
    );
  }

  @override
  $SalesItemsTable createAlias(String alias) {
    return $SalesItemsTable(attachedDatabase, alias);
  }
}

class SalesItemRow extends DataClass implements Insertable<SalesItemRow> {
  final int id;
  final String invoiceId;
  final String productId;
  final String productName;
  final double price;
  final double cost;
  final double quantity;
  final String priceCurrency;
  final double fxRate;
  final double priceOriginal;
  final double discount;
  final String attributesSnapshot;
  final String saleType;
  final String serialSnapshot;
  const SalesItemRow(
      {required this.id,
      required this.invoiceId,
      required this.productId,
      required this.productName,
      required this.price,
      required this.cost,
      required this.quantity,
      required this.priceCurrency,
      required this.fxRate,
      required this.priceOriginal,
      required this.discount,
      required this.attributesSnapshot,
      required this.saleType,
      required this.serialSnapshot});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['price'] = Variable<double>(price);
    map['cost'] = Variable<double>(cost);
    map['quantity'] = Variable<double>(quantity);
    map['price_currency'] = Variable<String>(priceCurrency);
    map['fx_rate'] = Variable<double>(fxRate);
    map['price_original'] = Variable<double>(priceOriginal);
    map['discount'] = Variable<double>(discount);
    map['attributes_snapshot'] = Variable<String>(attributesSnapshot);
    map['sale_type'] = Variable<String>(saleType);
    map['serial_snapshot'] = Variable<String>(serialSnapshot);
    return map;
  }

  SalesItemsCompanion toCompanion(bool nullToAbsent) {
    return SalesItemsCompanion(
      id: Value(id),
      invoiceId: Value(invoiceId),
      productId: Value(productId),
      productName: Value(productName),
      price: Value(price),
      cost: Value(cost),
      quantity: Value(quantity),
      priceCurrency: Value(priceCurrency),
      fxRate: Value(fxRate),
      priceOriginal: Value(priceOriginal),
      discount: Value(discount),
      attributesSnapshot: Value(attributesSnapshot),
      saleType: Value(saleType),
      serialSnapshot: Value(serialSnapshot),
    );
  }

  factory SalesItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesItemRow(
      id: serializer.fromJson<int>(json['id']),
      invoiceId: serializer.fromJson<String>(json['invoiceId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      price: serializer.fromJson<double>(json['price']),
      cost: serializer.fromJson<double>(json['cost']),
      quantity: serializer.fromJson<double>(json['quantity']),
      priceCurrency: serializer.fromJson<String>(json['priceCurrency']),
      fxRate: serializer.fromJson<double>(json['fxRate']),
      priceOriginal: serializer.fromJson<double>(json['priceOriginal']),
      discount: serializer.fromJson<double>(json['discount']),
      attributesSnapshot:
          serializer.fromJson<String>(json['attributesSnapshot']),
      saleType: serializer.fromJson<String>(json['saleType']),
      serialSnapshot: serializer.fromJson<String>(json['serialSnapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'invoiceId': serializer.toJson<String>(invoiceId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'price': serializer.toJson<double>(price),
      'cost': serializer.toJson<double>(cost),
      'quantity': serializer.toJson<double>(quantity),
      'priceCurrency': serializer.toJson<String>(priceCurrency),
      'fxRate': serializer.toJson<double>(fxRate),
      'priceOriginal': serializer.toJson<double>(priceOriginal),
      'discount': serializer.toJson<double>(discount),
      'attributesSnapshot': serializer.toJson<String>(attributesSnapshot),
      'saleType': serializer.toJson<String>(saleType),
      'serialSnapshot': serializer.toJson<String>(serialSnapshot),
    };
  }

  SalesItemRow copyWith(
          {int? id,
          String? invoiceId,
          String? productId,
          String? productName,
          double? price,
          double? cost,
          double? quantity,
          String? priceCurrency,
          double? fxRate,
          double? priceOriginal,
          double? discount,
          String? attributesSnapshot,
          String? saleType,
          String? serialSnapshot}) =>
      SalesItemRow(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        quantity: quantity ?? this.quantity,
        priceCurrency: priceCurrency ?? this.priceCurrency,
        fxRate: fxRate ?? this.fxRate,
        priceOriginal: priceOriginal ?? this.priceOriginal,
        discount: discount ?? this.discount,
        attributesSnapshot: attributesSnapshot ?? this.attributesSnapshot,
        saleType: saleType ?? this.saleType,
        serialSnapshot: serialSnapshot ?? this.serialSnapshot,
      );
  SalesItemRow copyWithCompanion(SalesItemsCompanion data) {
    return SalesItemRow(
      id: data.id.present ? data.id.value : this.id,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      price: data.price.present ? data.price.value : this.price,
      cost: data.cost.present ? data.cost.value : this.cost,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      priceCurrency: data.priceCurrency.present
          ? data.priceCurrency.value
          : this.priceCurrency,
      fxRate: data.fxRate.present ? data.fxRate.value : this.fxRate,
      priceOriginal: data.priceOriginal.present
          ? data.priceOriginal.value
          : this.priceOriginal,
      discount: data.discount.present ? data.discount.value : this.discount,
      attributesSnapshot: data.attributesSnapshot.present
          ? data.attributesSnapshot.value
          : this.attributesSnapshot,
      saleType: data.saleType.present ? data.saleType.value : this.saleType,
      serialSnapshot: data.serialSnapshot.present
          ? data.serialSnapshot.value
          : this.serialSnapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesItemRow(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('quantity: $quantity, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('priceOriginal: $priceOriginal, ')
          ..write('discount: $discount, ')
          ..write('attributesSnapshot: $attributesSnapshot, ')
          ..write('saleType: $saleType, ')
          ..write('serialSnapshot: $serialSnapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      invoiceId,
      productId,
      productName,
      price,
      cost,
      quantity,
      priceCurrency,
      fxRate,
      priceOriginal,
      discount,
      attributesSnapshot,
      saleType,
      serialSnapshot);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesItemRow &&
          other.id == this.id &&
          other.invoiceId == this.invoiceId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.price == this.price &&
          other.cost == this.cost &&
          other.quantity == this.quantity &&
          other.priceCurrency == this.priceCurrency &&
          other.fxRate == this.fxRate &&
          other.priceOriginal == this.priceOriginal &&
          other.discount == this.discount &&
          other.attributesSnapshot == this.attributesSnapshot &&
          other.saleType == this.saleType &&
          other.serialSnapshot == this.serialSnapshot);
}

class SalesItemsCompanion extends UpdateCompanion<SalesItemRow> {
  final Value<int> id;
  final Value<String> invoiceId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<double> price;
  final Value<double> cost;
  final Value<double> quantity;
  final Value<String> priceCurrency;
  final Value<double> fxRate;
  final Value<double> priceOriginal;
  final Value<double> discount;
  final Value<String> attributesSnapshot;
  final Value<String> saleType;
  final Value<String> serialSnapshot;
  const SalesItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.quantity = const Value.absent(),
    this.priceCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.priceOriginal = const Value.absent(),
    this.discount = const Value.absent(),
    this.attributesSnapshot = const Value.absent(),
    this.saleType = const Value.absent(),
    this.serialSnapshot = const Value.absent(),
  });
  SalesItemsCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceId,
    required String productId,
    required String productName,
    required double price,
    this.cost = const Value.absent(),
    required double quantity,
    this.priceCurrency = const Value.absent(),
    this.fxRate = const Value.absent(),
    this.priceOriginal = const Value.absent(),
    this.discount = const Value.absent(),
    this.attributesSnapshot = const Value.absent(),
    this.saleType = const Value.absent(),
    this.serialSnapshot = const Value.absent(),
  })  : invoiceId = Value(invoiceId),
        productId = Value(productId),
        productName = Value(productName),
        price = Value(price),
        quantity = Value(quantity);
  static Insertable<SalesItemRow> custom({
    Expression<int>? id,
    Expression<String>? invoiceId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<double>? price,
    Expression<double>? cost,
    Expression<double>? quantity,
    Expression<String>? priceCurrency,
    Expression<double>? fxRate,
    Expression<double>? priceOriginal,
    Expression<double>? discount,
    Expression<String>? attributesSnapshot,
    Expression<String>? saleType,
    Expression<String>? serialSnapshot,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (quantity != null) 'quantity': quantity,
      if (priceCurrency != null) 'price_currency': priceCurrency,
      if (fxRate != null) 'fx_rate': fxRate,
      if (priceOriginal != null) 'price_original': priceOriginal,
      if (discount != null) 'discount': discount,
      if (attributesSnapshot != null) 'attributes_snapshot': attributesSnapshot,
      if (saleType != null) 'sale_type': saleType,
      if (serialSnapshot != null) 'serial_snapshot': serialSnapshot,
    });
  }

  SalesItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? invoiceId,
      Value<String>? productId,
      Value<String>? productName,
      Value<double>? price,
      Value<double>? cost,
      Value<double>? quantity,
      Value<String>? priceCurrency,
      Value<double>? fxRate,
      Value<double>? priceOriginal,
      Value<double>? discount,
      Value<String>? attributesSnapshot,
      Value<String>? saleType,
      Value<String>? serialSnapshot}) {
    return SalesItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
      priceCurrency: priceCurrency ?? this.priceCurrency,
      fxRate: fxRate ?? this.fxRate,
      priceOriginal: priceOriginal ?? this.priceOriginal,
      discount: discount ?? this.discount,
      attributesSnapshot: attributesSnapshot ?? this.attributesSnapshot,
      saleType: saleType ?? this.saleType,
      serialSnapshot: serialSnapshot ?? this.serialSnapshot,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (cost.present) {
      map['cost'] = Variable<double>(cost.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (priceCurrency.present) {
      map['price_currency'] = Variable<String>(priceCurrency.value);
    }
    if (fxRate.present) {
      map['fx_rate'] = Variable<double>(fxRate.value);
    }
    if (priceOriginal.present) {
      map['price_original'] = Variable<double>(priceOriginal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (attributesSnapshot.present) {
      map['attributes_snapshot'] = Variable<String>(attributesSnapshot.value);
    }
    if (saleType.present) {
      map['sale_type'] = Variable<String>(saleType.value);
    }
    if (serialSnapshot.present) {
      map['serial_snapshot'] = Variable<String>(serialSnapshot.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesItemsCompanion(')
          ..write('id: $id, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('price: $price, ')
          ..write('cost: $cost, ')
          ..write('quantity: $quantity, ')
          ..write('priceCurrency: $priceCurrency, ')
          ..write('fxRate: $fxRate, ')
          ..write('priceOriginal: $priceOriginal, ')
          ..write('discount: $discount, ')
          ..write('attributesSnapshot: $attributesSnapshot, ')
          ..write('saleType: $saleType, ')
          ..write('serialSnapshot: $serialSnapshot')
          ..write(')'))
        .toString();
  }
}

class $CustomersTable extends Customers
    with TableInfo<$CustomersTable, CustomerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, note, createdAt, isArchived];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'customers';
  @override
  VerificationContext validateIntegrity(Insertable<CustomerRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomerRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $CustomersTable createAlias(String alias) {
    return $CustomersTable(attachedDatabase, alias);
  }
}

class CustomerRow extends DataClass implements Insertable<CustomerRow> {
  final String id;
  final String name;
  final String phone;
  final String note;

  /// Stored as milliseconds since epoch.
  final int createdAt;

  /// Soft-hide a customer without deleting their ledger history.
  final bool isArchived;
  const CustomerRow(
      {required this.id,
      required this.name,
      required this.phone,
      required this.note,
      required this.createdAt,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  CustomersCompanion toCompanion(bool nullToAbsent) {
    return CustomersCompanion(
      id: Value(id),
      name: Value(name),
      phone: Value(phone),
      note: Value(note),
      createdAt: Value(createdAt),
      isArchived: Value(isArchived),
    );
  }

  factory CustomerRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomerRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  CustomerRow copyWith(
          {String? id,
          String? name,
          String? phone,
          String? note,
          int? createdAt,
          bool? isArchived}) =>
      CustomerRow(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        isArchived: isArchived ?? this.isArchived,
      );
  CustomerRow copyWithCompanion(CustomersCompanion data) {
    return CustomerRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomerRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, note, createdAt, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.isArchived == this.isArchived);
}

class CustomersCompanion extends UpdateCompanion<CustomerRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> phone;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const CustomersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomersCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<CustomerRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomersCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? phone,
      Value<String>? note,
      Value<int>? createdAt,
      Value<bool>? isArchived,
      Value<int>? rowid}) {
    return CustomersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerEntriesTable extends LedgerEntries
    with TableInfo<$LedgerEntriesTable, LedgerEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _invoiceIdMeta =
      const VerificationMeta('invoiceId');
  @override
  late final GeneratedColumn<String> invoiceId = GeneratedColumn<String>(
      'invoice_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _entryTypeMeta =
      const VerificationMeta('entryType');
  @override
  late final GeneratedColumn<String> entryType = GeneratedColumn<String>(
      'entry_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, customerId, invoiceId, entryType, amount, note, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledger_entries';
  @override
  VerificationContext validateIntegrity(Insertable<LedgerEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    } else if (isInserting) {
      context.missing(_customerIdMeta);
    }
    if (data.containsKey('invoice_id')) {
      context.handle(_invoiceIdMeta,
          invoiceId.isAcceptableOrUnknown(data['invoice_id']!, _invoiceIdMeta));
    }
    if (data.containsKey('entry_type')) {
      context.handle(_entryTypeMeta,
          entryType.isAcceptableOrUnknown(data['entry_type']!, _entryTypeMeta));
    } else if (isInserting) {
      context.missing(_entryTypeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id'])!,
      invoiceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}invoice_id']),
      entryType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entry_type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LedgerEntriesTable createAlias(String alias) {
    return $LedgerEntriesTable(attachedDatabase, alias);
  }
}

class LedgerEntryRow extends DataClass implements Insertable<LedgerEntryRow> {
  final String id;
  final String customerId;

  /// Set when this entry was auto-created by a credit sale (links to
  /// `sales_invoices.id`); null for a manual charge or payment.
  final String? invoiceId;

  /// 'charge' (customer owes more) or 'payment' (customer paid).
  final String entryType;

  /// Always positive; the sign comes from [entryType]. Money stays `double`
  /// (app-wide convention), rounded to 2 decimals at write time.
  final double amount;
  final String note;

  /// Stored as milliseconds since epoch.
  final int createdAt;
  const LedgerEntryRow(
      {required this.id,
      required this.customerId,
      this.invoiceId,
      required this.entryType,
      required this.amount,
      required this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['customer_id'] = Variable<String>(customerId);
    if (!nullToAbsent || invoiceId != null) {
      map['invoice_id'] = Variable<String>(invoiceId);
    }
    map['entry_type'] = Variable<String>(entryType);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return LedgerEntriesCompanion(
      id: Value(id),
      customerId: Value(customerId),
      invoiceId: invoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceId),
      entryType: Value(entryType),
      amount: Value(amount),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory LedgerEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerEntryRow(
      id: serializer.fromJson<String>(json['id']),
      customerId: serializer.fromJson<String>(json['customerId']),
      invoiceId: serializer.fromJson<String?>(json['invoiceId']),
      entryType: serializer.fromJson<String>(json['entryType']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'customerId': serializer.toJson<String>(customerId),
      'invoiceId': serializer.toJson<String?>(invoiceId),
      'entryType': serializer.toJson<String>(entryType),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LedgerEntryRow copyWith(
          {String? id,
          String? customerId,
          Value<String?> invoiceId = const Value.absent(),
          String? entryType,
          double? amount,
          String? note,
          int? createdAt}) =>
      LedgerEntryRow(
        id: id ?? this.id,
        customerId: customerId ?? this.customerId,
        invoiceId: invoiceId.present ? invoiceId.value : this.invoiceId,
        entryType: entryType ?? this.entryType,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  LedgerEntryRow copyWithCompanion(LedgerEntriesCompanion data) {
    return LedgerEntryRow(
      id: data.id.present ? data.id.value : this.id,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      invoiceId: data.invoiceId.present ? data.invoiceId.value : this.invoiceId,
      entryType: data.entryType.present ? data.entryType.value : this.entryType,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntryRow(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, customerId, invoiceId, entryType, amount, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerEntryRow &&
          other.id == this.id &&
          other.customerId == this.customerId &&
          other.invoiceId == this.invoiceId &&
          other.entryType == this.entryType &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class LedgerEntriesCompanion extends UpdateCompanion<LedgerEntryRow> {
  final Value<String> id;
  final Value<String> customerId;
  final Value<String?> invoiceId;
  final Value<String> entryType;
  final Value<double> amount;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const LedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.customerId = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.entryType = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerEntriesCompanion.insert({
    required String id,
    required String customerId,
    this.invoiceId = const Value.absent(),
    required String entryType,
    required double amount,
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        customerId = Value(customerId),
        entryType = Value(entryType),
        amount = Value(amount),
        createdAt = Value(createdAt);
  static Insertable<LedgerEntryRow> custom({
    Expression<String>? id,
    Expression<String>? customerId,
    Expression<String>? invoiceId,
    Expression<String>? entryType,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (entryType != null) 'entry_type': entryType,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerEntriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? customerId,
      Value<String?>? invoiceId,
      Value<String>? entryType,
      Value<double>? amount,
      Value<String>? note,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return LedgerEntriesCompanion(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (invoiceId.present) {
      map['invoice_id'] = Variable<String>(invoiceId.value);
    }
    if (entryType.present) {
      map['entry_type'] = Variable<String>(entryType.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('customerId: $customerId, ')
          ..write('invoiceId: $invoiceId, ')
          ..write('entryType: $entryType, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashboxTransactionsTable extends CashboxTransactions
    with TableInfo<$CashboxTransactionsTable, CashboxTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashboxTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _relatedIdMeta =
      const VerificationMeta('relatedId');
  @override
  late final GeneratedColumn<String> relatedId = GeneratedColumn<String>(
      'related_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, amount, note, relatedId, occurredAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cashbox_transactions';
  @override
  VerificationContext validateIntegrity(
      Insertable<CashboxTransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('related_id')) {
      context.handle(_relatedIdMeta,
          relatedId.isAcceptableOrUnknown(data['related_id']!, _relatedIdMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CashboxTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashboxTransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      relatedId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}related_id']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CashboxTransactionsTable createAlias(String alias) {
    return $CashboxTransactionsTable(attachedDatabase, alias);
  }
}

class CashboxTransactionRow extends DataClass
    implements Insertable<CashboxTransactionRow> {
  final String id;

  /// `CashTransactionType.name` — persisted by name string, never index.
  final String type;

  /// Signed: `+` = cash in, `−` = cash out. Balance = `SUM(amount)`. Money stays
  /// `double` (app-wide convention), rounded to 2 decimals at write time.
  final double amount;
  final String note;

  /// Source link: invoice id (cash sale) or ledger-entry id (debt payment);
  /// null for a manual entry.
  final String? relatedId;

  /// Transaction (business) date — the Today/date-range filters key off this.
  /// Stored as milliseconds since epoch.
  final int occurredAt;

  /// Audit insertion time (milliseconds since epoch).
  final int createdAt;
  const CashboxTransactionRow(
      {required this.id,
      required this.type,
      required this.amount,
      required this.note,
      this.relatedId,
      required this.occurredAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || relatedId != null) {
      map['related_id'] = Variable<String>(relatedId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  CashboxTransactionsCompanion toCompanion(bool nullToAbsent) {
    return CashboxTransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      note: Value(note),
      relatedId: relatedId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedId),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory CashboxTransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashboxTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      note: serializer.fromJson<String>(json['note']),
      relatedId: serializer.fromJson<String?>(json['relatedId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'note': serializer.toJson<String>(note),
      'relatedId': serializer.toJson<String?>(relatedId),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  CashboxTransactionRow copyWith(
          {String? id,
          String? type,
          double? amount,
          String? note,
          Value<String?> relatedId = const Value.absent(),
          int? occurredAt,
          int? createdAt}) =>
      CashboxTransactionRow(
        id: id ?? this.id,
        type: type ?? this.type,
        amount: amount ?? this.amount,
        note: note ?? this.note,
        relatedId: relatedId.present ? relatedId.value : this.relatedId,
        occurredAt: occurredAt ?? this.occurredAt,
        createdAt: createdAt ?? this.createdAt,
      );
  CashboxTransactionRow copyWithCompanion(CashboxTransactionsCompanion data) {
    return CashboxTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      note: data.note.present ? data.note.value : this.note,
      relatedId: data.relatedId.present ? data.relatedId.value : this.relatedId,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashboxTransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('relatedId: $relatedId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, amount, note, relatedId, occurredAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashboxTransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.note == this.note &&
          other.relatedId == this.relatedId &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class CashboxTransactionsCompanion
    extends UpdateCompanion<CashboxTransactionRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<String> note;
  final Value<String?> relatedId;
  final Value<int> occurredAt;
  final Value<int> createdAt;
  final Value<int> rowid;
  const CashboxTransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.note = const Value.absent(),
    this.relatedId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashboxTransactionsCompanion.insert({
    required String id,
    required String type,
    required double amount,
    this.note = const Value.absent(),
    this.relatedId = const Value.absent(),
    required int occurredAt,
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        amount = Value(amount),
        occurredAt = Value(occurredAt),
        createdAt = Value(createdAt);
  static Insertable<CashboxTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<String>? note,
    Expression<String>? relatedId,
    Expression<int>? occurredAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (note != null) 'note': note,
      if (relatedId != null) 'related_id': relatedId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashboxTransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<double>? amount,
      Value<String>? note,
      Value<String?>? relatedId,
      Value<int>? occurredAt,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return CashboxTransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      relatedId: relatedId ?? this.relatedId,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (relatedId.present) {
      map['related_id'] = Variable<String>(relatedId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashboxTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('note: $note, ')
          ..write('relatedId: $relatedId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttributeDefinitionsTable extends AttributeDefinitions
    with TableInfo<$AttributeDefinitionsTable, AttributeDefinitionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttributeDefinitionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('text'));
  static const VerificationMeta _optionsMeta =
      const VerificationMeta('options');
  @override
  late final GeneratedColumn<String> options = GeneratedColumn<String>(
      'options', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _isRequiredMeta =
      const VerificationMeta('isRequired');
  @override
  late final GeneratedColumn<bool> isRequired = GeneratedColumn<bool>(
      'is_required', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_required" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _showInListMeta =
      const VerificationMeta('showInList');
  @override
  late final GeneratedColumn<bool> showInList = GeneratedColumn<bool>(
      'show_in_list', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_in_list" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _showOnReceiptMeta =
      const VerificationMeta('showOnReceipt');
  @override
  late final GeneratedColumn<bool> showOnReceipt = GeneratedColumn<bool>(
      'show_on_receipt', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("show_on_receipt" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isArchivedMeta =
      const VerificationMeta('isArchived');
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
      'is_archived', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_archived" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        label,
        type,
        options,
        unit,
        isRequired,
        showInList,
        showOnReceipt,
        sortOrder,
        isArchived
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attribute_definitions';
  @override
  VerificationContext validateIntegrity(
      Insertable<AttributeDefinitionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    }
    if (data.containsKey('options')) {
      context.handle(_optionsMeta,
          options.isAcceptableOrUnknown(data['options']!, _optionsMeta));
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    }
    if (data.containsKey('is_required')) {
      context.handle(
          _isRequiredMeta,
          isRequired.isAcceptableOrUnknown(
              data['is_required']!, _isRequiredMeta));
    }
    if (data.containsKey('show_in_list')) {
      context.handle(
          _showInListMeta,
          showInList.isAcceptableOrUnknown(
              data['show_in_list']!, _showInListMeta));
    }
    if (data.containsKey('show_on_receipt')) {
      context.handle(
          _showOnReceiptMeta,
          showOnReceipt.isAcceptableOrUnknown(
              data['show_on_receipt']!, _showOnReceiptMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('is_archived')) {
      context.handle(
          _isArchivedMeta,
          isArchived.isAcceptableOrUnknown(
              data['is_archived']!, _isArchivedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttributeDefinitionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttributeDefinitionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      options: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}options'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      isRequired: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_required'])!,
      showInList: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_in_list'])!,
      showOnReceipt: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}show_on_receipt'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      isArchived: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_archived'])!,
    );
  }

  @override
  $AttributeDefinitionsTable createAlias(String alias) {
    return $AttributeDefinitionsTable(attachedDatabase, alias);
  }
}

class AttributeDefinitionRow extends DataClass
    implements Insertable<AttributeDefinitionRow> {
  final String id;
  final String label;
  final String type;
  final String options;
  final String unit;
  final bool isRequired;
  final bool showInList;
  final bool showOnReceipt;
  final int sortOrder;
  final bool isArchived;
  const AttributeDefinitionRow(
      {required this.id,
      required this.label,
      required this.type,
      required this.options,
      required this.unit,
      required this.isRequired,
      required this.showInList,
      required this.showOnReceipt,
      required this.sortOrder,
      required this.isArchived});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['type'] = Variable<String>(type);
    map['options'] = Variable<String>(options);
    map['unit'] = Variable<String>(unit);
    map['is_required'] = Variable<bool>(isRequired);
    map['show_in_list'] = Variable<bool>(showInList);
    map['show_on_receipt'] = Variable<bool>(showOnReceipt);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_archived'] = Variable<bool>(isArchived);
    return map;
  }

  AttributeDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return AttributeDefinitionsCompanion(
      id: Value(id),
      label: Value(label),
      type: Value(type),
      options: Value(options),
      unit: Value(unit),
      isRequired: Value(isRequired),
      showInList: Value(showInList),
      showOnReceipt: Value(showOnReceipt),
      sortOrder: Value(sortOrder),
      isArchived: Value(isArchived),
    );
  }

  factory AttributeDefinitionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttributeDefinitionRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      type: serializer.fromJson<String>(json['type']),
      options: serializer.fromJson<String>(json['options']),
      unit: serializer.fromJson<String>(json['unit']),
      isRequired: serializer.fromJson<bool>(json['isRequired']),
      showInList: serializer.fromJson<bool>(json['showInList']),
      showOnReceipt: serializer.fromJson<bool>(json['showOnReceipt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'type': serializer.toJson<String>(type),
      'options': serializer.toJson<String>(options),
      'unit': serializer.toJson<String>(unit),
      'isRequired': serializer.toJson<bool>(isRequired),
      'showInList': serializer.toJson<bool>(showInList),
      'showOnReceipt': serializer.toJson<bool>(showOnReceipt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isArchived': serializer.toJson<bool>(isArchived),
    };
  }

  AttributeDefinitionRow copyWith(
          {String? id,
          String? label,
          String? type,
          String? options,
          String? unit,
          bool? isRequired,
          bool? showInList,
          bool? showOnReceipt,
          int? sortOrder,
          bool? isArchived}) =>
      AttributeDefinitionRow(
        id: id ?? this.id,
        label: label ?? this.label,
        type: type ?? this.type,
        options: options ?? this.options,
        unit: unit ?? this.unit,
        isRequired: isRequired ?? this.isRequired,
        showInList: showInList ?? this.showInList,
        showOnReceipt: showOnReceipt ?? this.showOnReceipt,
        sortOrder: sortOrder ?? this.sortOrder,
        isArchived: isArchived ?? this.isArchived,
      );
  AttributeDefinitionRow copyWithCompanion(AttributeDefinitionsCompanion data) {
    return AttributeDefinitionRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      type: data.type.present ? data.type.value : this.type,
      options: data.options.present ? data.options.value : this.options,
      unit: data.unit.present ? data.unit.value : this.unit,
      isRequired:
          data.isRequired.present ? data.isRequired.value : this.isRequired,
      showInList:
          data.showInList.present ? data.showInList.value : this.showInList,
      showOnReceipt: data.showOnReceipt.present
          ? data.showOnReceipt.value
          : this.showOnReceipt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isArchived:
          data.isArchived.present ? data.isArchived.value : this.isArchived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttributeDefinitionRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('unit: $unit, ')
          ..write('isRequired: $isRequired, ')
          ..write('showInList: $showInList, ')
          ..write('showOnReceipt: $showOnReceipt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, type, options, unit, isRequired,
      showInList, showOnReceipt, sortOrder, isArchived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttributeDefinitionRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.type == this.type &&
          other.options == this.options &&
          other.unit == this.unit &&
          other.isRequired == this.isRequired &&
          other.showInList == this.showInList &&
          other.showOnReceipt == this.showOnReceipt &&
          other.sortOrder == this.sortOrder &&
          other.isArchived == this.isArchived);
}

class AttributeDefinitionsCompanion
    extends UpdateCompanion<AttributeDefinitionRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> type;
  final Value<String> options;
  final Value<String> unit;
  final Value<bool> isRequired;
  final Value<bool> showInList;
  final Value<bool> showOnReceipt;
  final Value<int> sortOrder;
  final Value<bool> isArchived;
  final Value<int> rowid;
  const AttributeDefinitionsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.unit = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.showInList = const Value.absent(),
    this.showOnReceipt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttributeDefinitionsCompanion.insert({
    required String id,
    required String label,
    this.type = const Value.absent(),
    this.options = const Value.absent(),
    this.unit = const Value.absent(),
    this.isRequired = const Value.absent(),
    this.showInList = const Value.absent(),
    this.showOnReceipt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label);
  static Insertable<AttributeDefinitionRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? type,
    Expression<String>? options,
    Expression<String>? unit,
    Expression<bool>? isRequired,
    Expression<bool>? showInList,
    Expression<bool>? showOnReceipt,
    Expression<int>? sortOrder,
    Expression<bool>? isArchived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (type != null) 'type': type,
      if (options != null) 'options': options,
      if (unit != null) 'unit': unit,
      if (isRequired != null) 'is_required': isRequired,
      if (showInList != null) 'show_in_list': showInList,
      if (showOnReceipt != null) 'show_on_receipt': showOnReceipt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isArchived != null) 'is_archived': isArchived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttributeDefinitionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? type,
      Value<String>? options,
      Value<String>? unit,
      Value<bool>? isRequired,
      Value<bool>? showInList,
      Value<bool>? showOnReceipt,
      Value<int>? sortOrder,
      Value<bool>? isArchived,
      Value<int>? rowid}) {
    return AttributeDefinitionsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? this.options,
      unit: unit ?? this.unit,
      isRequired: isRequired ?? this.isRequired,
      showInList: showInList ?? this.showInList,
      showOnReceipt: showOnReceipt ?? this.showOnReceipt,
      sortOrder: sortOrder ?? this.sortOrder,
      isArchived: isArchived ?? this.isArchived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (options.present) {
      map['options'] = Variable<String>(options.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (isRequired.present) {
      map['is_required'] = Variable<bool>(isRequired.value);
    }
    if (showInList.present) {
      map['show_in_list'] = Variable<bool>(showInList.value);
    }
    if (showOnReceipt.present) {
      map['show_on_receipt'] = Variable<bool>(showOnReceipt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttributeDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('type: $type, ')
          ..write('options: $options, ')
          ..write('unit: $unit, ')
          ..write('isRequired: $isRequired, ')
          ..write('showInList: $showInList, ')
          ..write('showOnReceipt: $showOnReceipt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isArchived: $isArchived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductUnitsTable extends ProductUnits
    with TableInfo<$ProductUnitsTable, ProductUnitRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductUnitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _serialMeta = const VerificationMeta('serial');
  @override
  late final GeneratedColumn<String> serial = GeneratedColumn<String>(
      'serial', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('inStock'));
  static const VerificationMeta _soldInvoiceIdMeta =
      const VerificationMeta('soldInvoiceId');
  @override
  late final GeneratedColumn<String> soldInvoiceId = GeneratedColumn<String>(
      'sold_invoice_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _soldAtMeta = const VerificationMeta('soldAt');
  @override
  late final GeneratedColumn<int> soldAt = GeneratedColumn<int>(
      'sold_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _warrantyUntilMeta =
      const VerificationMeta('warrantyUntil');
  @override
  late final GeneratedColumn<int> warrantyUntil = GeneratedColumn<int>(
      'warranty_until', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productId,
        serial,
        status,
        soldInvoiceId,
        soldAt,
        warrantyUntil,
        note,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_units';
  @override
  VerificationContext validateIntegrity(Insertable<ProductUnitRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('serial')) {
      context.handle(_serialMeta,
          serial.isAcceptableOrUnknown(data['serial']!, _serialMeta));
    } else if (isInserting) {
      context.missing(_serialMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('sold_invoice_id')) {
      context.handle(
          _soldInvoiceIdMeta,
          soldInvoiceId.isAcceptableOrUnknown(
              data['sold_invoice_id']!, _soldInvoiceIdMeta));
    }
    if (data.containsKey('sold_at')) {
      context.handle(_soldAtMeta,
          soldAt.isAcceptableOrUnknown(data['sold_at']!, _soldAtMeta));
    }
    if (data.containsKey('warranty_until')) {
      context.handle(
          _warrantyUntilMeta,
          warrantyUntil.isAcceptableOrUnknown(
              data['warranty_until']!, _warrantyUntilMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductUnitRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductUnitRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      serial: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}serial'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      soldInvoiceId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sold_invoice_id'])!,
      soldAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sold_at'])!,
      warrantyUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}warranty_until'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $ProductUnitsTable createAlias(String alias) {
    return $ProductUnitsTable(attachedDatabase, alias);
  }
}

class ProductUnitRow extends DataClass implements Insertable<ProductUnitRow> {
  final String id;

  /// The SKU this unit is one instance of.
  final String productId;

  /// The IMEI / serial number. Globally unique among non-empty values, enforced
  /// by a partial-unique index — an IMEI identifies one handset on earth, so a
  /// shop must not be able to enter it twice and sell one phone twice.
  final String serial;

  /// [UnitStatus] name ('inStock' | 'sold' | 'returned' | 'defective'). Stored
  /// by name, never index — the same rule as ProductSaleType/PriceCurrency, so
  /// reordering enum cases can't remap existing rows. Unknown values decode
  /// back to 'inStock'.
  final String status;

  /// The invoice that sold this unit; '' while unsold. This is the *lookup*
  /// direction (serial → invoice). It is not redundant with the
  /// `sales_items.serialSnapshot` written at sale time: the snapshot survives
  /// this row being deleted, and this link survives line edits.
  final String soldInvoiceId;

  /// Sale time, ms since epoch; 0 while unsold.
  final int soldAt;

  /// Warranty expiry, ms since epoch; 0 = no warranty recorded. Answers the
  /// question a phone shop is actually asked across the counter.
  final int warrantyUntil;
  final String note;
  final int createdAt;
  const ProductUnitRow(
      {required this.id,
      required this.productId,
      required this.serial,
      required this.status,
      required this.soldInvoiceId,
      required this.soldAt,
      required this.warrantyUntil,
      required this.note,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['serial'] = Variable<String>(serial);
    map['status'] = Variable<String>(status);
    map['sold_invoice_id'] = Variable<String>(soldInvoiceId);
    map['sold_at'] = Variable<int>(soldAt);
    map['warranty_until'] = Variable<int>(warrantyUntil);
    map['note'] = Variable<String>(note);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ProductUnitsCompanion toCompanion(bool nullToAbsent) {
    return ProductUnitsCompanion(
      id: Value(id),
      productId: Value(productId),
      serial: Value(serial),
      status: Value(status),
      soldInvoiceId: Value(soldInvoiceId),
      soldAt: Value(soldAt),
      warrantyUntil: Value(warrantyUntil),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory ProductUnitRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductUnitRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      serial: serializer.fromJson<String>(json['serial']),
      status: serializer.fromJson<String>(json['status']),
      soldInvoiceId: serializer.fromJson<String>(json['soldInvoiceId']),
      soldAt: serializer.fromJson<int>(json['soldAt']),
      warrantyUntil: serializer.fromJson<int>(json['warrantyUntil']),
      note: serializer.fromJson<String>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'serial': serializer.toJson<String>(serial),
      'status': serializer.toJson<String>(status),
      'soldInvoiceId': serializer.toJson<String>(soldInvoiceId),
      'soldAt': serializer.toJson<int>(soldAt),
      'warrantyUntil': serializer.toJson<int>(warrantyUntil),
      'note': serializer.toJson<String>(note),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ProductUnitRow copyWith(
          {String? id,
          String? productId,
          String? serial,
          String? status,
          String? soldInvoiceId,
          int? soldAt,
          int? warrantyUntil,
          String? note,
          int? createdAt}) =>
      ProductUnitRow(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        serial: serial ?? this.serial,
        status: status ?? this.status,
        soldInvoiceId: soldInvoiceId ?? this.soldInvoiceId,
        soldAt: soldAt ?? this.soldAt,
        warrantyUntil: warrantyUntil ?? this.warrantyUntil,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
      );
  ProductUnitRow copyWithCompanion(ProductUnitsCompanion data) {
    return ProductUnitRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      serial: data.serial.present ? data.serial.value : this.serial,
      status: data.status.present ? data.status.value : this.status,
      soldInvoiceId: data.soldInvoiceId.present
          ? data.soldInvoiceId.value
          : this.soldInvoiceId,
      soldAt: data.soldAt.present ? data.soldAt.value : this.soldAt,
      warrantyUntil: data.warrantyUntil.present
          ? data.warrantyUntil.value
          : this.warrantyUntil,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('serial: $serial, ')
          ..write('status: $status, ')
          ..write('soldInvoiceId: $soldInvoiceId, ')
          ..write('soldAt: $soldAt, ')
          ..write('warrantyUntil: $warrantyUntil, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, serial, status, soldInvoiceId,
      soldAt, warrantyUntil, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductUnitRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.serial == this.serial &&
          other.status == this.status &&
          other.soldInvoiceId == this.soldInvoiceId &&
          other.soldAt == this.soldAt &&
          other.warrantyUntil == this.warrantyUntil &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class ProductUnitsCompanion extends UpdateCompanion<ProductUnitRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> serial;
  final Value<String> status;
  final Value<String> soldInvoiceId;
  final Value<int> soldAt;
  final Value<int> warrantyUntil;
  final Value<String> note;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ProductUnitsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.serial = const Value.absent(),
    this.status = const Value.absent(),
    this.soldInvoiceId = const Value.absent(),
    this.soldAt = const Value.absent(),
    this.warrantyUntil = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductUnitsCompanion.insert({
    required String id,
    required String productId,
    required String serial,
    this.status = const Value.absent(),
    this.soldInvoiceId = const Value.absent(),
    this.soldAt = const Value.absent(),
    this.warrantyUntil = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        productId = Value(productId),
        serial = Value(serial),
        createdAt = Value(createdAt);
  static Insertable<ProductUnitRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? serial,
    Expression<String>? status,
    Expression<String>? soldInvoiceId,
    Expression<int>? soldAt,
    Expression<int>? warrantyUntil,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (serial != null) 'serial': serial,
      if (status != null) 'status': status,
      if (soldInvoiceId != null) 'sold_invoice_id': soldInvoiceId,
      if (soldAt != null) 'sold_at': soldAt,
      if (warrantyUntil != null) 'warranty_until': warrantyUntil,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductUnitsCompanion copyWith(
      {Value<String>? id,
      Value<String>? productId,
      Value<String>? serial,
      Value<String>? status,
      Value<String>? soldInvoiceId,
      Value<int>? soldAt,
      Value<int>? warrantyUntil,
      Value<String>? note,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return ProductUnitsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      serial: serial ?? this.serial,
      status: status ?? this.status,
      soldInvoiceId: soldInvoiceId ?? this.soldInvoiceId,
      soldAt: soldAt ?? this.soldAt,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (serial.present) {
      map['serial'] = Variable<String>(serial.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (soldInvoiceId.present) {
      map['sold_invoice_id'] = Variable<String>(soldInvoiceId.value);
    }
    if (soldAt.present) {
      map['sold_at'] = Variable<int>(soldAt.value);
    }
    if (warrantyUntil.present) {
      map['warranty_until'] = Variable<int>(warrantyUntil.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductUnitsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('serial: $serial, ')
          ..write('status: $status, ')
          ..write('soldInvoiceId: $soldInvoiceId, ')
          ..write('soldAt: $soldAt, ')
          ..write('warrantyUntil: $warrantyUntil, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ShopSettingsTable shopSettings = $ShopSettingsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $SalesInvoicesTable salesInvoices = $SalesInvoicesTable(this);
  late final $SalesItemsTable salesItems = $SalesItemsTable(this);
  late final $CustomersTable customers = $CustomersTable(this);
  late final $LedgerEntriesTable ledgerEntries = $LedgerEntriesTable(this);
  late final $CashboxTransactionsTable cashboxTransactions =
      $CashboxTransactionsTable(this);
  late final $AttributeDefinitionsTable attributeDefinitions =
      $AttributeDefinitionsTable(this);
  late final $ProductUnitsTable productUnits = $ProductUnitsTable(this);
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final ShopDao shopDao = ShopDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final SalesDao salesDao = SalesDao(this as AppDatabase);
  late final CustomersDao customersDao = CustomersDao(this as AppDatabase);
  late final LedgerDao ledgerDao = LedgerDao(this as AppDatabase);
  late final CashboxDao cashboxDao = CashboxDao(this as AppDatabase);
  late final DashboardDao dashboardDao = DashboardDao(this as AppDatabase);
  late final AttributesDao attributesDao = AttributesDao(this as AppDatabase);
  late final ProductUnitsDao productUnitsDao =
      ProductUnitsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        products,
        shopSettings,
        appSettings,
        salesInvoices,
        salesItems,
        customers,
        ledgerEntries,
        cashboxTransactions,
        attributeDefinitions,
        productUnits
      ];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String name,
  Value<String> barcode,
  required double price,
  Value<double> cost,
  Value<double> quantity,
  Value<double> minStockAlert,
  Value<String> saleType,
  Value<String> priceCurrency,
  Value<String> attributes,
  Value<bool> isSerialized,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> barcode,
  Value<double> price,
  Value<double> cost,
  Value<double> quantity,
  Value<double> minStockAlert,
  Value<String> saleType,
  Value<String> priceCurrency,
  Value<String> attributes,
  Value<bool> isSerialized,
  Value<int> rowid,
});

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minStockAlert => $composableBuilder(
      column: $table.minStockAlert, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saleType => $composableBuilder(
      column: $table.saleType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributes => $composableBuilder(
      column: $table.attributes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSerialized => $composableBuilder(
      column: $table.isSerialized, builder: (column) => ColumnFilters(column));
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minStockAlert => $composableBuilder(
      column: $table.minStockAlert,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saleType => $composableBuilder(
      column: $table.saleType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributes => $composableBuilder(
      column: $table.attributes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSerialized => $composableBuilder(
      column: $table.isSerialized,
      builder: (column) => ColumnOrderings(column));
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get minStockAlert => $composableBuilder(
      column: $table.minStockAlert, builder: (column) => column);

  GeneratedColumn<String> get saleType =>
      $composableBuilder(column: $table.saleType, builder: (column) => column);

  GeneratedColumn<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency, builder: (column) => column);

  GeneratedColumn<String> get attributes => $composableBuilder(
      column: $table.attributes, builder: (column) => column);

  GeneratedColumn<bool> get isSerialized => $composableBuilder(
      column: $table.isSerialized, builder: (column) => column);
}

class $$ProductsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
    ProductRow,
    PrefetchHooks Function()> {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> barcode = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> cost = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> minStockAlert = const Value.absent(),
            Value<String> saleType = const Value.absent(),
            Value<String> priceCurrency = const Value.absent(),
            Value<String> attributes = const Value.absent(),
            Value<bool> isSerialized = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            barcode: barcode,
            price: price,
            cost: cost,
            quantity: quantity,
            minStockAlert: minStockAlert,
            saleType: saleType,
            priceCurrency: priceCurrency,
            attributes: attributes,
            isSerialized: isSerialized,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> barcode = const Value.absent(),
            required double price,
            Value<double> cost = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> minStockAlert = const Value.absent(),
            Value<String> saleType = const Value.absent(),
            Value<String> priceCurrency = const Value.absent(),
            Value<String> attributes = const Value.absent(),
            Value<bool> isSerialized = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            barcode: barcode,
            price: price,
            cost: cost,
            quantity: quantity,
            minStockAlert: minStockAlert,
            saleType: saleType,
            priceCurrency: priceCurrency,
            attributes: attributes,
            isSerialized: isSerialized,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsTable,
    ProductRow,
    $$ProductsTableFilterComposer,
    $$ProductsTableOrderingComposer,
    $$ProductsTableAnnotationComposer,
    $$ProductsTableCreateCompanionBuilder,
    $$ProductsTableUpdateCompanionBuilder,
    (ProductRow, BaseReferences<_$AppDatabase, $ProductsTable, ProductRow>),
    ProductRow,
    PrefetchHooks Function()>;
typedef $$ShopSettingsTableCreateCompanionBuilder = ShopSettingsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> addressLine1,
  Value<String> addressLine2,
  Value<String> phoneNumber,
  Value<String> footerText,
  Value<String> currencySymbol,
  Value<int> rowid,
});
typedef $$ShopSettingsTableUpdateCompanionBuilder = ShopSettingsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> addressLine1,
  Value<String> addressLine2,
  Value<String> phoneNumber,
  Value<String> footerText,
  Value<String> currencySymbol,
  Value<int> rowid,
});

class $$ShopSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $ShopSettingsTable> {
  $$ShopSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addressLine1 => $composableBuilder(
      column: $table.addressLine1, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get addressLine2 => $composableBuilder(
      column: $table.addressLine2, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get footerText => $composableBuilder(
      column: $table.footerText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnFilters(column));
}

class $$ShopSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShopSettingsTable> {
  $$ShopSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addressLine1 => $composableBuilder(
      column: $table.addressLine1,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addressLine2 => $composableBuilder(
      column: $table.addressLine2,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get footerText => $composableBuilder(
      column: $table.footerText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol,
      builder: (column) => ColumnOrderings(column));
}

class $$ShopSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShopSettingsTable> {
  $$ShopSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get addressLine1 => $composableBuilder(
      column: $table.addressLine1, builder: (column) => column);

  GeneratedColumn<String> get addressLine2 => $composableBuilder(
      column: $table.addressLine2, builder: (column) => column);

  GeneratedColumn<String> get phoneNumber => $composableBuilder(
      column: $table.phoneNumber, builder: (column) => column);

  GeneratedColumn<String> get footerText => $composableBuilder(
      column: $table.footerText, builder: (column) => column);

  GeneratedColumn<String> get currencySymbol => $composableBuilder(
      column: $table.currencySymbol, builder: (column) => column);
}

class $$ShopSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShopSettingsTable,
    ShopRow,
    $$ShopSettingsTableFilterComposer,
    $$ShopSettingsTableOrderingComposer,
    $$ShopSettingsTableAnnotationComposer,
    $$ShopSettingsTableCreateCompanionBuilder,
    $$ShopSettingsTableUpdateCompanionBuilder,
    (ShopRow, BaseReferences<_$AppDatabase, $ShopSettingsTable, ShopRow>),
    ShopRow,
    PrefetchHooks Function()> {
  $$ShopSettingsTableTableManager(_$AppDatabase db, $ShopSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShopSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShopSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShopSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> addressLine1 = const Value.absent(),
            Value<String> addressLine2 = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<String> footerText = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShopSettingsCompanion(
            id: id,
            name: name,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            phoneNumber: phoneNumber,
            footerText: footerText,
            currencySymbol: currencySymbol,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> addressLine1 = const Value.absent(),
            Value<String> addressLine2 = const Value.absent(),
            Value<String> phoneNumber = const Value.absent(),
            Value<String> footerText = const Value.absent(),
            Value<String> currencySymbol = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShopSettingsCompanion.insert(
            id: id,
            name: name,
            addressLine1: addressLine1,
            addressLine2: addressLine2,
            phoneNumber: phoneNumber,
            footerText: footerText,
            currencySymbol: currencySymbol,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ShopSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShopSettingsTable,
    ShopRow,
    $$ShopSettingsTableFilterComposer,
    $$ShopSettingsTableOrderingComposer,
    $$ShopSettingsTableAnnotationComposer,
    $$ShopSettingsTableCreateCompanionBuilder,
    $$ShopSettingsTableUpdateCompanionBuilder,
    (ShopRow, BaseReferences<_$AppDatabase, $ShopSettingsTable, ShopRow>),
    ShopRow,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    SettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    SettingRow,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (SettingRow, BaseReferences<_$AppDatabase, $AppSettingsTable, SettingRow>),
    SettingRow,
    PrefetchHooks Function()>;
typedef $$SalesInvoicesTableCreateCompanionBuilder = SalesInvoicesCompanion
    Function({
  required String id,
  required int createdAt,
  required double totalAmount,
  Value<double> invoiceDiscount,
  Value<int> rowid,
});
typedef $$SalesInvoicesTableUpdateCompanionBuilder = SalesInvoicesCompanion
    Function({
  Value<String> id,
  Value<int> createdAt,
  Value<double> totalAmount,
  Value<double> invoiceDiscount,
  Value<int> rowid,
});

class $$SalesInvoicesTableFilterComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTable> {
  $$SalesInvoicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get invoiceDiscount => $composableBuilder(
      column: $table.invoiceDiscount,
      builder: (column) => ColumnFilters(column));
}

class $$SalesInvoicesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTable> {
  $$SalesInvoicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get invoiceDiscount => $composableBuilder(
      column: $table.invoiceDiscount,
      builder: (column) => ColumnOrderings(column));
}

class $$SalesInvoicesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesInvoicesTable> {
  $$SalesInvoicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get invoiceDiscount => $composableBuilder(
      column: $table.invoiceDiscount, builder: (column) => column);
}

class $$SalesInvoicesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesInvoicesTable,
    SalesInvoiceRow,
    $$SalesInvoicesTableFilterComposer,
    $$SalesInvoicesTableOrderingComposer,
    $$SalesInvoicesTableAnnotationComposer,
    $$SalesInvoicesTableCreateCompanionBuilder,
    $$SalesInvoicesTableUpdateCompanionBuilder,
    (
      SalesInvoiceRow,
      BaseReferences<_$AppDatabase, $SalesInvoicesTable, SalesInvoiceRow>
    ),
    SalesInvoiceRow,
    PrefetchHooks Function()> {
  $$SalesInvoicesTableTableManager(_$AppDatabase db, $SalesInvoicesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesInvoicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesInvoicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesInvoicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> invoiceDiscount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesInvoicesCompanion(
            id: id,
            createdAt: createdAt,
            totalAmount: totalAmount,
            invoiceDiscount: invoiceDiscount,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int createdAt,
            required double totalAmount,
            Value<double> invoiceDiscount = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesInvoicesCompanion.insert(
            id: id,
            createdAt: createdAt,
            totalAmount: totalAmount,
            invoiceDiscount: invoiceDiscount,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesInvoicesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesInvoicesTable,
    SalesInvoiceRow,
    $$SalesInvoicesTableFilterComposer,
    $$SalesInvoicesTableOrderingComposer,
    $$SalesInvoicesTableAnnotationComposer,
    $$SalesInvoicesTableCreateCompanionBuilder,
    $$SalesInvoicesTableUpdateCompanionBuilder,
    (
      SalesInvoiceRow,
      BaseReferences<_$AppDatabase, $SalesInvoicesTable, SalesInvoiceRow>
    ),
    SalesInvoiceRow,
    PrefetchHooks Function()>;
typedef $$SalesItemsTableCreateCompanionBuilder = SalesItemsCompanion Function({
  Value<int> id,
  required String invoiceId,
  required String productId,
  required String productName,
  required double price,
  Value<double> cost,
  required double quantity,
  Value<String> priceCurrency,
  Value<double> fxRate,
  Value<double> priceOriginal,
  Value<double> discount,
  Value<String> attributesSnapshot,
  Value<String> saleType,
  Value<String> serialSnapshot,
});
typedef $$SalesItemsTableUpdateCompanionBuilder = SalesItemsCompanion Function({
  Value<int> id,
  Value<String> invoiceId,
  Value<String> productId,
  Value<String> productName,
  Value<double> price,
  Value<double> cost,
  Value<double> quantity,
  Value<String> priceCurrency,
  Value<double> fxRate,
  Value<double> priceOriginal,
  Value<double> discount,
  Value<String> attributesSnapshot,
  Value<String> saleType,
  Value<String> serialSnapshot,
});

class $$SalesItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SalesItemsTable> {
  $$SalesItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get fxRate => $composableBuilder(
      column: $table.fxRate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get priceOriginal => $composableBuilder(
      column: $table.priceOriginal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributesSnapshot => $composableBuilder(
      column: $table.attributesSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saleType => $composableBuilder(
      column: $table.saleType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serialSnapshot => $composableBuilder(
      column: $table.serialSnapshot,
      builder: (column) => ColumnFilters(column));
}

class $$SalesItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesItemsTable> {
  $$SalesItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get price => $composableBuilder(
      column: $table.price, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get cost => $composableBuilder(
      column: $table.cost, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get fxRate => $composableBuilder(
      column: $table.fxRate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get priceOriginal => $composableBuilder(
      column: $table.priceOriginal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributesSnapshot => $composableBuilder(
      column: $table.attributesSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saleType => $composableBuilder(
      column: $table.saleType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serialSnapshot => $composableBuilder(
      column: $table.serialSnapshot,
      builder: (column) => ColumnOrderings(column));
}

class $$SalesItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesItemsTable> {
  $$SalesItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get cost =>
      $composableBuilder(column: $table.cost, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get priceCurrency => $composableBuilder(
      column: $table.priceCurrency, builder: (column) => column);

  GeneratedColumn<double> get fxRate =>
      $composableBuilder(column: $table.fxRate, builder: (column) => column);

  GeneratedColumn<double> get priceOriginal => $composableBuilder(
      column: $table.priceOriginal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<String> get attributesSnapshot => $composableBuilder(
      column: $table.attributesSnapshot, builder: (column) => column);

  GeneratedColumn<String> get saleType =>
      $composableBuilder(column: $table.saleType, builder: (column) => column);

  GeneratedColumn<String> get serialSnapshot => $composableBuilder(
      column: $table.serialSnapshot, builder: (column) => column);
}

class $$SalesItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SalesItemsTable,
    SalesItemRow,
    $$SalesItemsTableFilterComposer,
    $$SalesItemsTableOrderingComposer,
    $$SalesItemsTableAnnotationComposer,
    $$SalesItemsTableCreateCompanionBuilder,
    $$SalesItemsTableUpdateCompanionBuilder,
    (
      SalesItemRow,
      BaseReferences<_$AppDatabase, $SalesItemsTable, SalesItemRow>
    ),
    SalesItemRow,
    PrefetchHooks Function()> {
  $$SalesItemsTableTableManager(_$AppDatabase db, $SalesItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> invoiceId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<double> price = const Value.absent(),
            Value<double> cost = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<String> priceCurrency = const Value.absent(),
            Value<double> fxRate = const Value.absent(),
            Value<double> priceOriginal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String> attributesSnapshot = const Value.absent(),
            Value<String> saleType = const Value.absent(),
            Value<String> serialSnapshot = const Value.absent(),
          }) =>
              SalesItemsCompanion(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            productName: productName,
            price: price,
            cost: cost,
            quantity: quantity,
            priceCurrency: priceCurrency,
            fxRate: fxRate,
            priceOriginal: priceOriginal,
            discount: discount,
            attributesSnapshot: attributesSnapshot,
            saleType: saleType,
            serialSnapshot: serialSnapshot,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String invoiceId,
            required String productId,
            required String productName,
            required double price,
            Value<double> cost = const Value.absent(),
            required double quantity,
            Value<String> priceCurrency = const Value.absent(),
            Value<double> fxRate = const Value.absent(),
            Value<double> priceOriginal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<String> attributesSnapshot = const Value.absent(),
            Value<String> saleType = const Value.absent(),
            Value<String> serialSnapshot = const Value.absent(),
          }) =>
              SalesItemsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            productName: productName,
            price: price,
            cost: cost,
            quantity: quantity,
            priceCurrency: priceCurrency,
            fxRate: fxRate,
            priceOriginal: priceOriginal,
            discount: discount,
            attributesSnapshot: attributesSnapshot,
            saleType: saleType,
            serialSnapshot: serialSnapshot,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SalesItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SalesItemsTable,
    SalesItemRow,
    $$SalesItemsTableFilterComposer,
    $$SalesItemsTableOrderingComposer,
    $$SalesItemsTableAnnotationComposer,
    $$SalesItemsTableCreateCompanionBuilder,
    $$SalesItemsTableUpdateCompanionBuilder,
    (
      SalesItemRow,
      BaseReferences<_$AppDatabase, $SalesItemsTable, SalesItemRow>
    ),
    SalesItemRow,
    PrefetchHooks Function()>;
typedef $$CustomersTableCreateCompanionBuilder = CustomersCompanion Function({
  required String id,
  required String name,
  Value<String> phone,
  Value<String> note,
  required int createdAt,
  Value<bool> isArchived,
  Value<int> rowid,
});
typedef $$CustomersTableUpdateCompanionBuilder = CustomersCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> phone,
  Value<String> note,
  Value<int> createdAt,
  Value<bool> isArchived,
  Value<int> rowid,
});

class $$CustomersTableFilterComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));
}

class $$CustomersTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));
}

class $$CustomersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomersTable> {
  $$CustomersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);
}

class $$CustomersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CustomersTable,
    CustomerRow,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (CustomerRow, BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>),
    CustomerRow,
    PrefetchHooks Function()> {
  $$CustomersTableTableManager(_$AppDatabase db, $CustomersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> phone = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion(
            id: id,
            name: name,
            phone: phone,
            note: note,
            createdAt: createdAt,
            isArchived: isArchived,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> phone = const Value.absent(),
            Value<String> note = const Value.absent(),
            required int createdAt,
            Value<bool> isArchived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CustomersCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            note: note,
            createdAt: createdAt,
            isArchived: isArchived,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CustomersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CustomersTable,
    CustomerRow,
    $$CustomersTableFilterComposer,
    $$CustomersTableOrderingComposer,
    $$CustomersTableAnnotationComposer,
    $$CustomersTableCreateCompanionBuilder,
    $$CustomersTableUpdateCompanionBuilder,
    (CustomerRow, BaseReferences<_$AppDatabase, $CustomersTable, CustomerRow>),
    CustomerRow,
    PrefetchHooks Function()>;
typedef $$LedgerEntriesTableCreateCompanionBuilder = LedgerEntriesCompanion
    Function({
  required String id,
  required String customerId,
  Value<String?> invoiceId,
  required String entryType,
  required double amount,
  Value<String> note,
  required int createdAt,
  Value<int> rowid,
});
typedef $$LedgerEntriesTableUpdateCompanionBuilder = LedgerEntriesCompanion
    Function({
  Value<String> id,
  Value<String> customerId,
  Value<String?> invoiceId,
  Value<String> entryType,
  Value<double> amount,
  Value<String> note,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$LedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$LedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get invoiceId => $composableBuilder(
      column: $table.invoiceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entryType => $composableBuilder(
      column: $table.entryType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerEntriesTable> {
  $$LedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get invoiceId =>
      $composableBuilder(column: $table.invoiceId, builder: (column) => column);

  GeneratedColumn<String> get entryType =>
      $composableBuilder(column: $table.entryType, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LedgerEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LedgerEntriesTable,
    LedgerEntryRow,
    $$LedgerEntriesTableFilterComposer,
    $$LedgerEntriesTableOrderingComposer,
    $$LedgerEntriesTableAnnotationComposer,
    $$LedgerEntriesTableCreateCompanionBuilder,
    $$LedgerEntriesTableUpdateCompanionBuilder,
    (
      LedgerEntryRow,
      BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntryRow>
    ),
    LedgerEntryRow,
    PrefetchHooks Function()> {
  $$LedgerEntriesTableTableManager(_$AppDatabase db, $LedgerEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> customerId = const Value.absent(),
            Value<String?> invoiceId = const Value.absent(),
            Value<String> entryType = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LedgerEntriesCompanion(
            id: id,
            customerId: customerId,
            invoiceId: invoiceId,
            entryType: entryType,
            amount: amount,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String customerId,
            Value<String?> invoiceId = const Value.absent(),
            required String entryType,
            required double amount,
            Value<String> note = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              LedgerEntriesCompanion.insert(
            id: id,
            customerId: customerId,
            invoiceId: invoiceId,
            entryType: entryType,
            amount: amount,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LedgerEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LedgerEntriesTable,
    LedgerEntryRow,
    $$LedgerEntriesTableFilterComposer,
    $$LedgerEntriesTableOrderingComposer,
    $$LedgerEntriesTableAnnotationComposer,
    $$LedgerEntriesTableCreateCompanionBuilder,
    $$LedgerEntriesTableUpdateCompanionBuilder,
    (
      LedgerEntryRow,
      BaseReferences<_$AppDatabase, $LedgerEntriesTable, LedgerEntryRow>
    ),
    LedgerEntryRow,
    PrefetchHooks Function()>;
typedef $$CashboxTransactionsTableCreateCompanionBuilder
    = CashboxTransactionsCompanion Function({
  required String id,
  required String type,
  required double amount,
  Value<String> note,
  Value<String?> relatedId,
  required int occurredAt,
  required int createdAt,
  Value<int> rowid,
});
typedef $$CashboxTransactionsTableUpdateCompanionBuilder
    = CashboxTransactionsCompanion Function({
  Value<String> id,
  Value<String> type,
  Value<double> amount,
  Value<String> note,
  Value<String?> relatedId,
  Value<int> occurredAt,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$CashboxTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $CashboxTransactionsTable> {
  $$CashboxTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedId => $composableBuilder(
      column: $table.relatedId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$CashboxTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashboxTransactionsTable> {
  $$CashboxTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedId => $composableBuilder(
      column: $table.relatedId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CashboxTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashboxTransactionsTable> {
  $$CashboxTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get relatedId =>
      $composableBuilder(column: $table.relatedId, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CashboxTransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CashboxTransactionsTable,
    CashboxTransactionRow,
    $$CashboxTransactionsTableFilterComposer,
    $$CashboxTransactionsTableOrderingComposer,
    $$CashboxTransactionsTableAnnotationComposer,
    $$CashboxTransactionsTableCreateCompanionBuilder,
    $$CashboxTransactionsTableUpdateCompanionBuilder,
    (
      CashboxTransactionRow,
      BaseReferences<_$AppDatabase, $CashboxTransactionsTable,
          CashboxTransactionRow>
    ),
    CashboxTransactionRow,
    PrefetchHooks Function()> {
  $$CashboxTransactionsTableTableManager(
      _$AppDatabase db, $CashboxTransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashboxTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashboxTransactionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashboxTransactionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> relatedId = const Value.absent(),
            Value<int> occurredAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CashboxTransactionsCompanion(
            id: id,
            type: type,
            amount: amount,
            note: note,
            relatedId: relatedId,
            occurredAt: occurredAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required double amount,
            Value<String> note = const Value.absent(),
            Value<String?> relatedId = const Value.absent(),
            required int occurredAt,
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CashboxTransactionsCompanion.insert(
            id: id,
            type: type,
            amount: amount,
            note: note,
            relatedId: relatedId,
            occurredAt: occurredAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CashboxTransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CashboxTransactionsTable,
    CashboxTransactionRow,
    $$CashboxTransactionsTableFilterComposer,
    $$CashboxTransactionsTableOrderingComposer,
    $$CashboxTransactionsTableAnnotationComposer,
    $$CashboxTransactionsTableCreateCompanionBuilder,
    $$CashboxTransactionsTableUpdateCompanionBuilder,
    (
      CashboxTransactionRow,
      BaseReferences<_$AppDatabase, $CashboxTransactionsTable,
          CashboxTransactionRow>
    ),
    CashboxTransactionRow,
    PrefetchHooks Function()>;
typedef $$AttributeDefinitionsTableCreateCompanionBuilder
    = AttributeDefinitionsCompanion Function({
  required String id,
  required String label,
  Value<String> type,
  Value<String> options,
  Value<String> unit,
  Value<bool> isRequired,
  Value<bool> showInList,
  Value<bool> showOnReceipt,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<int> rowid,
});
typedef $$AttributeDefinitionsTableUpdateCompanionBuilder
    = AttributeDefinitionsCompanion Function({
  Value<String> id,
  Value<String> label,
  Value<String> type,
  Value<String> options,
  Value<String> unit,
  Value<bool> isRequired,
  Value<bool> showInList,
  Value<bool> showOnReceipt,
  Value<int> sortOrder,
  Value<bool> isArchived,
  Value<int> rowid,
});

class $$AttributeDefinitionsTableFilterComposer
    extends Composer<_$AppDatabase, $AttributeDefinitionsTable> {
  $$AttributeDefinitionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get options => $composableBuilder(
      column: $table.options, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showInList => $composableBuilder(
      column: $table.showInList, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get showOnReceipt => $composableBuilder(
      column: $table.showOnReceipt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnFilters(column));
}

class $$AttributeDefinitionsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttributeDefinitionsTable> {
  $$AttributeDefinitionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get options => $composableBuilder(
      column: $table.options, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unit => $composableBuilder(
      column: $table.unit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showInList => $composableBuilder(
      column: $table.showInList, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get showOnReceipt => $composableBuilder(
      column: $table.showOnReceipt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => ColumnOrderings(column));
}

class $$AttributeDefinitionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttributeDefinitionsTable> {
  $$AttributeDefinitionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get options =>
      $composableBuilder(column: $table.options, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<bool> get isRequired => $composableBuilder(
      column: $table.isRequired, builder: (column) => column);

  GeneratedColumn<bool> get showInList => $composableBuilder(
      column: $table.showInList, builder: (column) => column);

  GeneratedColumn<bool> get showOnReceipt => $composableBuilder(
      column: $table.showOnReceipt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
      column: $table.isArchived, builder: (column) => column);
}

class $$AttributeDefinitionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AttributeDefinitionsTable,
    AttributeDefinitionRow,
    $$AttributeDefinitionsTableFilterComposer,
    $$AttributeDefinitionsTableOrderingComposer,
    $$AttributeDefinitionsTableAnnotationComposer,
    $$AttributeDefinitionsTableCreateCompanionBuilder,
    $$AttributeDefinitionsTableUpdateCompanionBuilder,
    (
      AttributeDefinitionRow,
      BaseReferences<_$AppDatabase, $AttributeDefinitionsTable,
          AttributeDefinitionRow>
    ),
    AttributeDefinitionRow,
    PrefetchHooks Function()> {
  $$AttributeDefinitionsTableTableManager(
      _$AppDatabase db, $AttributeDefinitionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttributeDefinitionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttributeDefinitionsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttributeDefinitionsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> options = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> isRequired = const Value.absent(),
            Value<bool> showInList = const Value.absent(),
            Value<bool> showOnReceipt = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributeDefinitionsCompanion(
            id: id,
            label: label,
            type: type,
            options: options,
            unit: unit,
            isRequired: isRequired,
            showInList: showInList,
            showOnReceipt: showOnReceipt,
            sortOrder: sortOrder,
            isArchived: isArchived,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            Value<String> type = const Value.absent(),
            Value<String> options = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<bool> isRequired = const Value.absent(),
            Value<bool> showInList = const Value.absent(),
            Value<bool> showOnReceipt = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<bool> isArchived = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttributeDefinitionsCompanion.insert(
            id: id,
            label: label,
            type: type,
            options: options,
            unit: unit,
            isRequired: isRequired,
            showInList: showInList,
            showOnReceipt: showOnReceipt,
            sortOrder: sortOrder,
            isArchived: isArchived,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AttributeDefinitionsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AttributeDefinitionsTable,
        AttributeDefinitionRow,
        $$AttributeDefinitionsTableFilterComposer,
        $$AttributeDefinitionsTableOrderingComposer,
        $$AttributeDefinitionsTableAnnotationComposer,
        $$AttributeDefinitionsTableCreateCompanionBuilder,
        $$AttributeDefinitionsTableUpdateCompanionBuilder,
        (
          AttributeDefinitionRow,
          BaseReferences<_$AppDatabase, $AttributeDefinitionsTable,
              AttributeDefinitionRow>
        ),
        AttributeDefinitionRow,
        PrefetchHooks Function()>;
typedef $$ProductUnitsTableCreateCompanionBuilder = ProductUnitsCompanion
    Function({
  required String id,
  required String productId,
  required String serial,
  Value<String> status,
  Value<String> soldInvoiceId,
  Value<int> soldAt,
  Value<int> warrantyUntil,
  Value<String> note,
  required int createdAt,
  Value<int> rowid,
});
typedef $$ProductUnitsTableUpdateCompanionBuilder = ProductUnitsCompanion
    Function({
  Value<String> id,
  Value<String> productId,
  Value<String> serial,
  Value<String> status,
  Value<String> soldInvoiceId,
  Value<int> soldAt,
  Value<int> warrantyUntil,
  Value<String> note,
  Value<int> createdAt,
  Value<int> rowid,
});

class $$ProductUnitsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductUnitsTable> {
  $$ProductUnitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get serial => $composableBuilder(
      column: $table.serial, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get soldInvoiceId => $composableBuilder(
      column: $table.soldInvoiceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get soldAt => $composableBuilder(
      column: $table.soldAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get warrantyUntil => $composableBuilder(
      column: $table.warrantyUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$ProductUnitsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductUnitsTable> {
  $$ProductUnitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get serial => $composableBuilder(
      column: $table.serial, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get soldInvoiceId => $composableBuilder(
      column: $table.soldInvoiceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get soldAt => $composableBuilder(
      column: $table.soldAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get warrantyUntil => $composableBuilder(
      column: $table.warrantyUntil,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductUnitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductUnitsTable> {
  $$ProductUnitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get serial =>
      $composableBuilder(column: $table.serial, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get soldInvoiceId => $composableBuilder(
      column: $table.soldInvoiceId, builder: (column) => column);

  GeneratedColumn<int> get soldAt =>
      $composableBuilder(column: $table.soldAt, builder: (column) => column);

  GeneratedColumn<int> get warrantyUntil => $composableBuilder(
      column: $table.warrantyUntil, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProductUnitsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductUnitsTable,
    ProductUnitRow,
    $$ProductUnitsTableFilterComposer,
    $$ProductUnitsTableOrderingComposer,
    $$ProductUnitsTableAnnotationComposer,
    $$ProductUnitsTableCreateCompanionBuilder,
    $$ProductUnitsTableUpdateCompanionBuilder,
    (
      ProductUnitRow,
      BaseReferences<_$AppDatabase, $ProductUnitsTable, ProductUnitRow>
    ),
    ProductUnitRow,
    PrefetchHooks Function()> {
  $$ProductUnitsTableTableManager(_$AppDatabase db, $ProductUnitsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductUnitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductUnitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductUnitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> serial = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> soldInvoiceId = const Value.absent(),
            Value<int> soldAt = const Value.absent(),
            Value<int> warrantyUntil = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductUnitsCompanion(
            id: id,
            productId: productId,
            serial: serial,
            status: status,
            soldInvoiceId: soldInvoiceId,
            soldAt: soldAt,
            warrantyUntil: warrantyUntil,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String productId,
            required String serial,
            Value<String> status = const Value.absent(),
            Value<String> soldInvoiceId = const Value.absent(),
            Value<int> soldAt = const Value.absent(),
            Value<int> warrantyUntil = const Value.absent(),
            Value<String> note = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductUnitsCompanion.insert(
            id: id,
            productId: productId,
            serial: serial,
            status: status,
            soldInvoiceId: soldInvoiceId,
            soldAt: soldAt,
            warrantyUntil: warrantyUntil,
            note: note,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductUnitsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductUnitsTable,
    ProductUnitRow,
    $$ProductUnitsTableFilterComposer,
    $$ProductUnitsTableOrderingComposer,
    $$ProductUnitsTableAnnotationComposer,
    $$ProductUnitsTableCreateCompanionBuilder,
    $$ProductUnitsTableUpdateCompanionBuilder,
    (
      ProductUnitRow,
      BaseReferences<_$AppDatabase, $ProductUnitsTable, ProductUnitRow>
    ),
    ProductUnitRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ShopSettingsTableTableManager get shopSettings =>
      $$ShopSettingsTableTableManager(_db, _db.shopSettings);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$SalesInvoicesTableTableManager get salesInvoices =>
      $$SalesInvoicesTableTableManager(_db, _db.salesInvoices);
  $$SalesItemsTableTableManager get salesItems =>
      $$SalesItemsTableTableManager(_db, _db.salesItems);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db, _db.customers);
  $$LedgerEntriesTableTableManager get ledgerEntries =>
      $$LedgerEntriesTableTableManager(_db, _db.ledgerEntries);
  $$CashboxTransactionsTableTableManager get cashboxTransactions =>
      $$CashboxTransactionsTableTableManager(_db, _db.cashboxTransactions);
  $$AttributeDefinitionsTableTableManager get attributeDefinitions =>
      $$AttributeDefinitionsTableTableManager(_db, _db.attributeDefinitions);
  $$ProductUnitsTableTableManager get productUnits =>
      $$ProductUnitsTableTableManager(_db, _db.productUnits);
}
