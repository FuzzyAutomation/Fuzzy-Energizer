import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzyenergizer/services/mqtt_service.dart';
import 'package:fuzzyenergizer/widgets/loading_overlay.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late MQTTService mqttService;
  String receivedData = '';
  String statusText = "Disconnected";
  bool isRelayOn = false;
  String statusMessage = 'Energizer is turned OFF';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService(
      onMessageReceived,
      onStatusChanged,
    );
    connectMQTT(); // Initiate connection and subscription here
  }

  Future<void> connectMQTT() async {
    try {
      await mqttService.connect();
      mqttService.subscribe('Energizer/data');
      setState(() {
        isLoading = false;
        statusText = "Connected";
      });
    } catch (e) {
      print('Failed to connect to MQTT: $e');
      setState(() {
        isLoading = false;
        statusText = "Connection failed";
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Connection Error'),
          content:
              Text('Failed to connect to MQTT server. Please try again later.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void onMessageReceived(String message) {
    setState(() {
      receivedData = message;
    });
  }

  void onStatusChanged(String status) {
    setState(() {
      statusText = status;
    });
  }

  void controlRelay() {
    setState(() {
      if (isRelayOn) {
        mqttService.publish('Energizer/commands', 'OFF');
        statusMessage = 'Energizer turned OFF';
      } else {
        mqttService.publish('Energizer/commands', 'ON');
        statusMessage = 'Energizer turned ON';
      }
      isRelayOn = !isRelayOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 1.2 * kToolbarHeight, 40, 20),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                // Your widget tree
                Align(
                  alignment: const AlignmentDirectional(3, -0.3),
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(-3, -0.3),
                  child: Container(
                    height: 300,
                    width: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, 16, 21, 154),
                    ),
                  ),
                ),
                Align(
                  alignment: const AlignmentDirectional(0, -1.2),
                  child: Container(
                    height: 300,
                    width: 600,
                    decoration: const BoxDecoration(
                      color: Color.fromARGB(255, 15, 32, 80),
                    ),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 100.0,
                    sigmaY: 100.0,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: controlRelay,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRelayOn ? Colors.green : Colors.red,
                            boxShadow: [
                              BoxShadow(
                                color: isRelayOn
                                    ? Colors.green.withOpacity(0.5)
                                    : const Color.fromARGB(255, 239, 125, 117)
                                        .withOpacity(0.5),
                                spreadRadius: 50,
                                blurRadius: 150,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.power_settings_new,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
