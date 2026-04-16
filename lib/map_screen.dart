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
        
        return Scaffold(
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 15,
                ),
                children: [
                  TileLayer(
                    urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.example.iot_smartshoe",
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 80,
                        height: 80,
                        child: const Icon(
                          Icons.location_pin,
                          size: 45,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppGradients.header,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [appShadow()],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          "Smart Shoe Location",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
