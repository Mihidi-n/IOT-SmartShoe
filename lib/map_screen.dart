import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'app_theme.dart';
import 'bluetooth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ble = BluetoothService.instance;

  @override
  void initState() {
    super.initState();
    ble.connectAndListen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: ble.sensorStream,
      initialData: ble.lastData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? ble.lastData;

        final latitude = (data["latitude"] ?? 6.9271).toDouble();
        final longitude = (data["longitude"] ?? 79.8612).toDouble();
