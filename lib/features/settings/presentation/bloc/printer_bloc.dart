import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/printer_repository.dart';
import 'printer_event.dart';
import 'printer_state.dart';

class PrinterBloc extends Bloc<PrinterEvent, PrinterState> {
  final PrinterRepository repository;

  PrinterBloc({required this.repository}) : super(const PrinterState()) {
    on<InitPrinterEvent>(_onInit);
    on<RefreshPrinterEvent>(_onRefresh);
    on<ScanPrintersEvent>(_onScan);
    on<ConnectPrinterEvent>(_onConnect);
    on<DisconnectPrinterEvent>(_onDisconnect);
    on<TestPrintEvent>(_onTestPrint);
  }

  Future<void> _onInit(InitPrinterEvent event, Emitter<PrinterState> emit) async {
    try {
      final mac = await repository.getSavedPrinterMac();
      final name = await repository.getSavedPrinterName();
      emit(state.copyWith(
        status: PrinterStatus.initial,
        connectedMac: mac,
        connectedName: name,
      ));
    } catch (_) {
      emit(state.copyWith(status: PrinterStatus.initial));
    }
  }

  Future<void> _onRefresh(
      RefreshPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    try {
      await _refresh(emit);
    } catch (_) {
      emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        error: PrinterError.scanFailed,
      ));
    }
  }

  Future<void> _refresh(Emitter<PrinterState> emit) async {
    final result = await repository.scanDevices();

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        error: _mapScanFailure(failure),
      )),
      (devices) async {
        if (devices.isEmpty) {
          emit(state.copyWith(
            status: PrinterStatus.scanFailure,
            error: PrinterError.noPairedDevices,
            devices: const [],
          ));
          return;
        }

        for (final device in devices) {
          if (await repository.connect(device.mac)) {
            await repository.savePrinterData(device.mac, device.name);
            emit(state.copyWith(
              status: PrinterStatus.connected,
              connectedMac: device.mac,
              connectedName: device.name,
              devices: devices,
              clearError: true,
            ));
            return;
          }
        }

        emit(state.copyWith(
          status: PrinterStatus.scanFailure,
          error: PrinterError.connectFailed,
          devices: devices,
        ));
      },
    );
  }

  Future<void> _onScan(
      ScanPrintersEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.scanning, clearError: true));
    final result = await repository.scanDevices();
    result.fold(
      (failure) => emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        error: _mapScanFailure(failure),
      )),
      (devices) => emit(state.copyWith(
        status: PrinterStatus.scanSuccess,
        devices: devices,
      )),
    );
  }

  Future<void> _onConnect(
      ConnectPrinterEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.connecting, clearError: true));
    try {
      final success = await repository.connect(event.mac);
      if (success) {
        await repository.savePrinterData(event.mac, event.name);
        emit(state.copyWith(
          status: PrinterStatus.connected,
          connectedMac: event.mac,
          connectedName: event.name,
        ));
      } else {
        emit(state.copyWith(
          status: PrinterStatus.connectionFailure,
          error: PrinterError.connectFailed,
        ));
      }
    } catch (_) {
      emit(state.copyWith(
        status: PrinterStatus.connectionFailure,
        error: PrinterError.connectFailed,
      ));
    }
  }

  Future<void> _onDisconnect(
      DisconnectPrinterEvent event, Emitter<PrinterState> emit) async {
    // Always land in the disconnected state, even if the calls throw — the
    // user asked to forget the printer.
    try {
      await repository.disconnect();
      await repository.clearPrinterData();
    } catch (_) {
      // Ignore: we still report disconnected below.
    }
    emit(PrinterState(
      status: PrinterStatus.disconnected,
      devices: state.devices,
    ));
  }

  Future<void> _onTestPrint(
      TestPrintEvent event, Emitter<PrinterState> emit) async {
    emit(state.copyWith(status: PrinterStatus.testPrinting));
    try {
      await repository.testPrint(event.shopName);
      emit(state.copyWith(status: PrinterStatus.scanSuccess));
    } catch (_) {
      emit(state.copyWith(
        status: PrinterStatus.scanFailure,
        error: PrinterError.connectFailed,
      ));
    }
  }

  PrinterError _mapScanFailure(Failure failure) =>
      failure is PermissionFailure
          ? PrinterError.permissionDenied
          : PrinterError.scanFailed;
}
