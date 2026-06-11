import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../core/constants/ble_constants.dart';

/// Connection state of the senior's phone to the mat.
enum MatConnState { disconnected, scanning, connecting, connected, notFound }

/// A focused Bluetooth client for the Play app: scans for the IncreMat mat,
/// connects, and streams the live rep count straight from the device — no
/// Firebase round-trip. The caregiver app keeps its own connection in parallel
/// (the firmware allows two simultaneous links).
class MatBleService {
  BluetoothDevice? _device;

  final _stateController =
      StreamController<MatConnState>.broadcast();
  final _repController = StreamController<int>.broadcast();
  final _matPlacedController = StreamController<bool>.broadcast();

  MatConnState _state = MatConnState.disconnected;
  int _lastReps = 0;
  bool _matPlaced = true;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _repCountSub;
  StreamSubscription<List<int>>? _matPlacedSub;

  Stream<MatConnState> get stateStream => _stateController.stream;
  Stream<int> get repCountStream => _repController.stream;
  Stream<bool> get matPlacedStream => _matPlacedController.stream;

  MatConnState get state => _state;
  int get lastReps => _lastReps;
  bool get matPlaced => _matPlaced;
  bool get isConnected => _state == MatConnState.connected;

  void _setState(MatConnState s) {
    _state = s;
    if (!_stateController.isClosed) _stateController.add(s);
  }

  /// Scans for and connects to the nearest IncreMat mat. Safe to call when
  /// already connected (no-op). Throws are swallowed into a [MatConnState].
  Future<void> connect() async {
    if (_state == MatConnState.connecting ||
        _state == MatConnState.scanning ||
        _state == MatConnState.connected) {
      return;
    }
    try {
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        await FlutterBluePlus.turnOn();
      }

      _setState(MatConnState.scanning);
      ScanResult? found;
      final sub = FlutterBluePlus.scanResults.listen((results) {
        found ??= results.firstOrNull;
      });
      await FlutterBluePlus.startScan(
        withNames: [BleConstants.deviceNamePrefix],
        timeout: const Duration(seconds: BleConstants.scanTimeoutSeconds),
      );
      await FlutterBluePlus.isScanning.where((s) => !s).first;
      await sub.cancel();

      if (found == null) {
        _setState(MatConnState.notFound);
        return;
      }

      _setState(MatConnState.connecting);
      _device = found!.device;
      await _device!.connect(
        timeout:
            const Duration(seconds: BleConstants.connectionTimeoutSeconds),
      );
      _connectionSub = _device!.connectionState.listen(_onConnectionState);
      await _discoverAndSubscribe();
      _setState(MatConnState.connected);
    } catch (_) {
      _setState(MatConnState.disconnected);
    }
  }

  void _onConnectionState(BluetoothConnectionState s) {
    if (s == BluetoothConnectionState.disconnected) {
      _setState(MatConnState.disconnected);
    }
  }

  Future<void> _discoverAndSubscribe() async {
    if (_device == null) return;
    final services = await _device!.discoverServices();
    for (final service in services) {
      if (service.uuid.toString().toLowerCase() !=
          BleConstants.serviceUuid.toLowerCase()) {
        continue;
      }
      for (final char in service.characteristics) {
        final uuid = char.uuid.toString().toLowerCase();
        if (uuid == BleConstants.repCountCharUuid.toLowerCase()) {
          await char.setNotifyValue(true);
          _repCountSub = char.onValueReceived.listen(_onRepCountData);
        } else if (uuid == BleConstants.matPlacedCharUuid.toLowerCase()) {
          await char.setNotifyValue(true);
          _matPlacedSub = char.onValueReceived.listen(_onMatPlacedData);
        }
      }
    }
  }

  // 2-byte little-endian uint16 = cumulative reps this session.
  void _onRepCountData(List<int> data) {
    if (data.length < 2) return;
    _lastReps = data[0] | (data[1] << 8);
    if (!_repController.isClosed) _repController.add(_lastReps);
  }

  void _onMatPlacedData(List<int> data) {
    if (data.isEmpty) return;
    _matPlaced = data[0] == 1;
    if (!_matPlacedController.isClosed) _matPlacedController.add(_matPlaced);
  }

  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    await _repCountSub?.cancel();
    await _matPlacedSub?.cancel();
    _connectionSub = null;
    _repCountSub = null;
    _matPlacedSub = null;
    try {
      await _device?.disconnect();
    } catch (_) {}
    _device = null;
    _lastReps = 0;
    _setState(MatConnState.disconnected);
  }

  void dispose() {
    _connectionSub?.cancel();
    _repCountSub?.cancel();
    _matPlacedSub?.cancel();
    _device?.disconnect();
    _stateController.close();
    _repController.close();
    _matPlacedController.close();
  }
}
