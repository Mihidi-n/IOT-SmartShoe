import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  BluetoothService._();
  static final BluetoothService instance = BluetoothService._();

  // CHANGE THESE TO MATCH YOUR ESP32 BLE SETUP
  static const String targetDeviceName = "SmartShoeESP32";
  static const String serviceUuid = "12345678-1234-1234-1234-1234567890ab";
  static const String characteristicUuid = "abcdefab-1234-1234-1234-abcdefabcdef";

  BluetoothDevice? _device;
  BluetoothCharacteristic? _notifyCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<List<int>>? _charSub;

  bool _isConnecting = false;
  bool _isConnected = false;

  final StreamController<Map<String, dynamic>> _sensorController =
  StreamController<Map<String, dynamic>>.broadcast();

  Map<String, dynamic> _lastData = {
    "steps": 0,
    "calories": 0,
    "weight": 0,
    "temperature": 0,
    "humidity": 0,
    "fall": false,
    "latitude": 6.9271,
    "longitude": 79.8612,
  };

  Stream<Map<String, dynamic>> get sensorStream => _sensorController.stream;
  Map<String, dynamic> get lastData => _lastData;
  bool get isConnected => _isConnected;

  Future<void> connectAndListen() async {
    if (_isConnecting || _isConnected) return;
    _isConnecting = true;

    try {
      if (await FlutterBluePlus.isSupported == false) {
        _isConnecting = false;
        return;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _isConnecting = false;
        return;
      }

      await FlutterBluePlus.stopScan();

      _scanSub?.cancel();
      _scanSub = FlutterBluePlus.scanResults.listen((results) async {
        for (final r in results) {
          final name = r.device.platformName;
          if (name == targetDeviceName) {
            await FlutterBluePlus.stopScan();
            await _scanSub?.cancel();
            _device = r.device;
            await _connectToDevice();
            return;
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));
    } catch (_) {
      _isConnecting = false;
    }
  }

  Future<void> _connectToDevice() async {
    try {
      if (_device == null) {
        _isConnecting = false;
        return;
      }

      await _device!.connect(timeout: const Duration(seconds: 10));
      final services = await _device!.discoverServices();

      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                characteristicUuid.toLowerCase()) {
              _notifyCharacteristic = characteristic;
              break;
            }
          }
        }
      }

      if (_notifyCharacteristic == null) {
        _isConnecting = false;
        return;
      }

      await _notifyCharacteristic!.setNotifyValue(true);

      _charSub?.cancel();
      _charSub = _notifyCharacteristic!.lastValueStream.listen((value) async {
        if (value.isEmpty) return;

        try {
          final raw = utf8.decode(value).trim();
          final decoded = jsonDecode(raw);

          final packet = Map<String, dynamic>.from(decoded);

          _lastData = {
            "steps": _asInt(packet["steps"]),
            "calories": _asInt(packet["calories"]),
            "weight": _asInt(packet["weight"]),
            "temperature": _asInt(packet["temperature"]),
            "humidity": _asInt(packet["humidity"]),
            "fall": _asBool(packet["fall"]),
            "latitude": _asDouble(packet["latitude"]),
            "longitude": _asDouble(packet["longitude"]),
          };

          _sensorController.add(_lastData);

          await FirebaseDatabase.instance.ref("smart_shoe/sensors").update(_lastData);
        } catch (_) {
          // ignore bad packets
        }
      });

      _isConnected = true;
      _isConnecting = false;
    } catch (_) {
      _isConnected = false;
      _isConnecting = false;
    }
  }

  Future<void> disconnect() async {
    await _charSub?.cancel();
    await _scanSub?.cancel();

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }

    _device = null;
    _notifyCharacteristic = null;
    _isConnected = false;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  double _asDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == "true" || s == "1";
  }
}