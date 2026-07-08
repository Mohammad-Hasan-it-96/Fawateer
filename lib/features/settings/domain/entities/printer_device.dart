import 'package:equatable/equatable.dart';

/// A Bluetooth printer the app can connect to. Domain-level stand-in for the
/// plugin's `BluetoothInfo`, so the domain layer doesn't depend on the
/// Bluetooth package.
class PrinterDevice extends Equatable {
  final String name;
  final String mac;

  const PrinterDevice({required this.name, required this.mac});

  @override
  List<Object?> get props => [name, mac];
}
