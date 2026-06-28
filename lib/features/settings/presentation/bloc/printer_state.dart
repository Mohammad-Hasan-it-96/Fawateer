import 'package:equatable/equatable.dart';
import '../../domain/entities/printer_device.dart';

enum PrinterStatus {
  initial,
  scanning,
  scanSuccess,
  scanFailure,
  connecting,
  connected,
  connectionFailure,
  disconnected,
  testPrinting
}

/// A localizable printer error. The BLoC sets the case; the page maps it to a
/// translated string — no user-facing English lives in the BLoC.
enum PrinterError {
  permissionDenied,
  noPairedDevices,
  connectFailed,
  scanFailed,
}

class PrinterState extends Equatable {
  final PrinterStatus status;
  final String? connectedMac;
  final String? connectedName;
  final List<PrinterDevice> devices;
  final PrinterError? error;

  const PrinterState({
    this.status = PrinterStatus.initial,
    this.connectedMac,
    this.connectedName,
    this.devices = const [],
    this.error,
  });

  PrinterState copyWith({
    PrinterStatus? status,
    String? connectedMac,
    String? connectedName,
    List<PrinterDevice>? devices,
    PrinterError? error,
    bool clearError = false,
  }) {
    return PrinterState(
      status: status ?? this.status,
      connectedMac: connectedMac ?? this.connectedMac,
      connectedName: connectedName ?? this.connectedName,
      devices: devices ?? this.devices,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, connectedMac, connectedName, devices, error];
}
