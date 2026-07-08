import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String note;
  final DateTime createdAt;
  final bool isArchived;

  const Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.note = '',
    required this.createdAt,
    this.isArchived = false,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? note,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, note, createdAt, isArchived];
}
