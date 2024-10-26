import "package:flutter/material.dart";
import 'package:flutter_map/flutter_map.dart';
import 'package:fuzzyenergizer/services/mqtt_service.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late MQTTService mqttService;
  String receivedData = "";
  String statusText = "Disconnected";
  double latitude = 26.85658;
  double longitude = 89.39347;
  List<String> receivedMessage = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            // later fetch from the Mqtt broker
            // 26.85658, 89.393472
            options: MapOptions(
                keepAlive: true,
                initialCenter: LatLng(latitude, longitude),
                initialZoom: 17),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
