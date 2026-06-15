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
  static const VerificationMeta _stockMeta = const VerificationMeta('stock');
  @override
  late final GeneratedColumn<int> stock = GeneratedColumn<int>(
      'stock', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [id, name, barcode, price, cost, stock];
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
    if (data.containsKey('stock')) {
      context.handle(
          _stockMeta, stock.isAcceptableOrUnknown(data['stock']!, _stockMeta));
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
      stock: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock'])!,
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
  final int stock;
  const ProductRow(
      {required this.id,
      required this.name,
      required this.barcode,
      required this.price,
      required this.cost,
      required this.stock});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['barcode'] = Variable<String>(barcode);
    map['price'] = Variable<double>(price);
    map['cost'] = Variable<double>(cost);
    map['stock'] = Variable<int>(stock);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      barcode: Value(barcode),
      price: Value(price),
      cost: Value(cost),
      stock: Value(stock),
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
      stock: serializer.fromJson<int>(json['stock']),
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
      'stock': serializer.toJson<int>(stock),
    };
  }

  ProductRow copyWith(
          {String? id,
          String? name,
          String? barcode,
          double? price,
          double? cost,
          int? stock}) =>
      ProductRow(
        id: id ?? this.id,
        name: name ?? this.name,
        barcode: barcode ?? this.barcode,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        stock: stock ?? this.stock,
      );
  ProductRow copyWithCompanion(ProductsCompanion data) {
    return ProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      price: data.price.present ? data.price.value : this.price,
      cost: data.cost.present ? data.cost.value : this.cost,
      stock: data.stock.present ? data.stock.value : this.stock,
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
          ..write('stock: $stock')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, barcode, price, cost, stock);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.barcode == this.barcode &&
          other.price == this.price &&
          other.cost == this.cost &&
          other.stock == this.stock);
}

class ProductsCompanion extends UpdateCompanion<ProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> barcode;
  final Value<double> price;
  final Value<double> cost;
  final Value<int> stock;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.barcode = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.stock = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.barcode = const Value.absent(),
    required double price,
    this.cost = const Value.absent(),
    this.stock = const Value.absent(),
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
    Expression<int>? stock,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (barcode != null) 'barcode': barcode,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (stock != null) 'stock': stock,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? barcode,
      Value<double>? price,
      Value<double>? cost,
      Value<int>? stock,
      Value<int>? rowid}) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      stock: stock ?? this.stock,
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
    if (stock.present) {
      map['stock'] = Variable<int>(stock.value);
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
          ..write('stock: $stock, ')
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
      defaultValue: const Constant('₹'));
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
  static const VerificationMeta _customerIdMeta =
      const VerificationMeta('customerId');
  @override
  late final GeneratedColumn<String> customerId = GeneratedColumn<String>(
      'customer_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customerNameMeta =
      const VerificationMeta('customerName');
  @override
  late final GeneratedColumn<String> customerName = GeneratedColumn<String>(
      'customer_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns =>
      [id, createdAt, totalAmount, customerId, customerName];
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
    if (data.containsKey('customer_id')) {
      context.handle(
          _customerIdMeta,
          customerId.isAcceptableOrUnknown(
              data['customer_id']!, _customerIdMeta));
    }
    if (data.containsKey('customer_name')) {
      context.handle(
          _customerNameMeta,
          customerName.isAcceptableOrUnknown(
              data['customer_name']!, _customerNameMeta));
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
      customerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_id']),
      customerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}customer_name'])!,
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
  final String? customerId;
  final String customerName;
  const SalesInvoiceRow(
      {required this.id,
      required this.createdAt,
      required this.totalAmount,
      this.customerId,
      required this.customerName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<int>(createdAt);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || customerId != null) {
      map['customer_id'] = Variable<String>(customerId);
    }
    map['customer_name'] = Variable<String>(customerName);
    return map;
  }

  SalesInvoicesCompanion toCompanion(bool nullToAbsent) {
    return SalesInvoicesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      totalAmount: Value(totalAmount),
      customerId: customerId == null && nullToAbsent
          ? const Value.absent()
          : Value(customerId),
      customerName: Value(customerName),
    );
  }

  factory SalesInvoiceRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalesInvoiceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      customerId: serializer.fromJson<String?>(json['customerId']),
      customerName: serializer.fromJson<String>(json['customerName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<int>(createdAt),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'customerId': serializer.toJson<String?>(customerId),
      'customerName': serializer.toJson<String>(customerName),
    };
  }

  SalesInvoiceRow copyWith(
          {String? id,
          int? createdAt,
          double? totalAmount,
          Value<String?> customerId = const Value.absent(),
          String? customerName}) =>
      SalesInvoiceRow(
        id: id ?? this.id,
        createdAt: createdAt ?? this.createdAt,
        totalAmount: totalAmount ?? this.totalAmount,
        customerId: customerId.present ? customerId.value : this.customerId,
        customerName: customerName ?? this.customerName,
      );
  SalesInvoiceRow copyWithCompanion(SalesInvoicesCompanion data) {
    return SalesInvoiceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      customerId:
          data.customerId.present ? data.customerId.value : this.customerId,
      customerName: data.customerName.present
          ? data.customerName.value
          : this.customerName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalesInvoiceRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, totalAmount, customerId, customerName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalesInvoiceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.totalAmount == this.totalAmount &&
          other.customerId == this.customerId &&
          other.customerName == this.customerName);
}

class SalesInvoicesCompanion extends UpdateCompanion<SalesInvoiceRow> {
  final Value<String> id;
  final Value<int> createdAt;
  final Value<double> totalAmount;
  final Value<String?> customerId;
  final Value<String> customerName;
  final Value<int> rowid;
  const SalesInvoicesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesInvoicesCompanion.insert({
    required String id,
    required int createdAt,
    required double totalAmount,
    this.customerId = const Value.absent(),
    this.customerName = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        createdAt = Value(createdAt),
        totalAmount = Value(totalAmount);
  static Insertable<SalesInvoiceRow> custom({
    Expression<String>? id,
    Expression<int>? createdAt,
    Expression<double>? totalAmount,
    Expression<String>? customerId,
    Expression<String>? customerName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesInvoicesCompanion copyWith(
      {Value<String>? id,
      Value<int>? createdAt,
      Value<double>? totalAmount,
      Value<String?>? customerId,
      Value<String>? customerName,
      Value<int>? rowid}) {
    return SalesInvoicesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      totalAmount: totalAmount ?? this.totalAmount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
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
    if (customerId.present) {
      map['customer_id'] = Variable<String>(customerId.value);
    }
    if (customerName.present) {
      map['customer_name'] = Variable<String>(customerName.value);
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
          ..write('customerId: $customerId, ')
          ..write('customerName: $customerName, ')
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
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
      'quantity', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, invoiceId, productId, productName, price, cost, quantity];
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
          .read(DriftSqlType.int, data['${effectivePrefix}quantity'])!,
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
  final int quantity;
  const SalesItemRow(
      {required this.id,
      required this.invoiceId,
      required this.productId,
      required this.productName,
      required this.price,
      required this.cost,
      required this.quantity});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['invoice_id'] = Variable<String>(invoiceId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['price'] = Variable<double>(price);
    map['cost'] = Variable<double>(cost);
    map['quantity'] = Variable<int>(quantity);
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
      quantity: serializer.fromJson<int>(json['quantity']),
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
      'quantity': serializer.toJson<int>(quantity),
    };
  }

  SalesItemRow copyWith(
          {int? id,
          String? invoiceId,
          String? productId,
          String? productName,
          double? price,
          double? cost,
          int? quantity}) =>
      SalesItemRow(
        id: id ?? this.id,
        invoiceId: invoiceId ?? this.invoiceId,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        price: price ?? this.price,
        cost: cost ?? this.cost,
        quantity: quantity ?? this.quantity,
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
          ..write('quantity: $quantity')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, invoiceId, productId, productName, price, cost, quantity);
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
          other.quantity == this.quantity);
}

class SalesItemsCompanion extends UpdateCompanion<SalesItemRow> {
  final Value<int> id;
  final Value<String> invoiceId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<double> price;
  final Value<double> cost;
  final Value<int> quantity;
  const SalesItemsCompanion({
    this.id = const Value.absent(),
    this.invoiceId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.price = const Value.absent(),
    this.cost = const Value.absent(),
    this.quantity = const Value.absent(),
  });
  SalesItemsCompanion.insert({
    this.id = const Value.absent(),
    required String invoiceId,
    required String productId,
    required String productName,
    required double price,
    this.cost = const Value.absent(),
    required int quantity,
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
    Expression<int>? quantity,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (invoiceId != null) 'invoice_id': invoiceId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (price != null) 'price': price,
      if (cost != null) 'cost': cost,
      if (quantity != null) 'quantity': quantity,
    });
  }

  SalesItemsCompanion copyWith(
      {Value<int>? id,
      Value<String>? invoiceId,
      Value<String>? productId,
      Value<String>? productName,
      Value<double>? price,
      Value<double>? cost,
      Value<int>? quantity}) {
    return SalesItemsCompanion(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      quantity: quantity ?? this.quantity,
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
      map['quantity'] = Variable<int>(quantity.value);
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
          ..write('quantity: $quantity')
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
  late final ProductsDao productsDao = ProductsDao(this as AppDatabase);
  late final ShopDao shopDao = ShopDao(this as AppDatabase);
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final SalesDao salesDao = SalesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [products, shopSettings, appSettings, salesInvoices, salesItems];
}

typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String name,
  Value<String> barcode,
  required double price,
  Value<double> cost,
  Value<int> stock,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> barcode,
  Value<double> price,
  Value<double> cost,
  Value<int> stock,
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

  ColumnFilters<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<int> get stock => $composableBuilder(
      column: $table.stock, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<int> get stock =>
      $composableBuilder(column: $table.stock, builder: (column) => column);
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
            Value<int> stock = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion(
            id: id,
            name: name,
            barcode: barcode,
            price: price,
            cost: cost,
            stock: stock,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> barcode = const Value.absent(),
            required double price,
            Value<double> cost = const Value.absent(),
            Value<int> stock = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCompanion.insert(
            id: id,
            name: name,
            barcode: barcode,
            price: price,
            cost: cost,
            stock: stock,
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
  Value<String?> customerId,
  Value<String> customerName,
  Value<int> rowid,
});
typedef $$SalesInvoicesTableUpdateCompanionBuilder = SalesInvoicesCompanion
    Function({
  Value<String> id,
  Value<int> createdAt,
  Value<double> totalAmount,
  Value<String?> customerId,
  Value<String> customerName,
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

  ColumnFilters<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customerName => $composableBuilder(
      column: $table.customerName,
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

  GeneratedColumn<String> get customerId => $composableBuilder(
      column: $table.customerId, builder: (column) => column);

  GeneratedColumn<String> get customerName => $composableBuilder(
      column: $table.customerName, builder: (column) => column);
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
            Value<String?> customerId = const Value.absent(),
            Value<String> customerName = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesInvoicesCompanion(
            id: id,
            createdAt: createdAt,
            totalAmount: totalAmount,
            customerId: customerId,
            customerName: customerName,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int createdAt,
            required double totalAmount,
            Value<String?> customerId = const Value.absent(),
            Value<String> customerName = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SalesInvoicesCompanion.insert(
            id: id,
            createdAt: createdAt,
            totalAmount: totalAmount,
            customerId: customerId,
            customerName: customerName,
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
  required int quantity,
});
typedef $$SalesItemsTableUpdateCompanionBuilder = SalesItemsCompanion Function({
  Value<int> id,
  Value<String> invoiceId,
  Value<String> productId,
  Value<String> productName,
  Value<double> price,
  Value<double> cost,
  Value<int> quantity,
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

  ColumnFilters<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<int> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);
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
            Value<int> quantity = const Value.absent(),
          }) =>
              SalesItemsCompanion(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            productName: productName,
            price: price,
            cost: cost,
            quantity: quantity,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String invoiceId,
            required String productId,
            required String productName,
            required double price,
            Value<double> cost = const Value.absent(),
            required int quantity,
          }) =>
              SalesItemsCompanion.insert(
            id: id,
            invoiceId: invoiceId,
            productId: productId,
            productName: productName,
            price: price,
            cost: cost,
            quantity: quantity,
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
}
