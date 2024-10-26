import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fuzzyenergizer/services/mqtt_service.dart';
import 'package:fuzzyenergizer/widgets/loading_overlay.dart';
import 'package:fl_chart/fl_chart.dart';

class DataPage extends StatefulWidget {
  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  late MQTTService mqttService;
  List<String> receivedDataList = [];
  String statusText = "Disconnected";
  bool isLoading = true;
  final int maxDataLimit = 100;
  List<FlSpot> voltageData = [];
  final int maxDataPoints = 100; // Adjust this value as needed

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService(
      onMessageReceived,
      onStatusChanged,
    );

    _loadDataFromStorage();

    mqttService.connect().then((_) {
      mqttService.subscribe('Energizer/data');
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _loadDataFromStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString('receivedData');

    if (storedData != null) {
      List<String> dataList = List<String>.from(jsonDecode(storedData));
      setState(() {
        receivedDataList = dataList;
        _updateVoltageData(dataList);
      });
    } else {
      // No stored data found, initialize with dummy data
      _initializeDummyData();
    }
  }

  Future<void> _saveDataToStorage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('receivedData', jsonEncode(receivedDataList));
  }

  void onMessageReceived(String message) {
    setState(() {
      receivedDataList.insert(0, message);
      if (receivedDataList.length > maxDataLimit) {
        receivedDataList.removeLast();
      }
      _saveDataToStorage();
      _updateVoltageData(receivedDataList);
    });
  }

  void _initializeDummyData() {
    // Generate 10 dummy data entries
    List<String> dummyDataList = List.generate(10, (index) {
      DateTime now = DateTime.now().subtract(Duration(minutes: 10 - index));
      String formattedDate = DateFormat('dd-MM-yyyy').format(now);
      String formattedTime = DateFormat('HH:mm:ss').format(now);
      double voltage = 200 + index * 2.5; // Arbitrary voltage values
      return '$formattedDate, $formattedTime, $voltage, 0, 0';
    });

    setState(() {
      receivedDataList = dummyDataList;
      _updateVoltageData(receivedDataList);
    });
  }

  void _updateVoltageData(List<String> dataList) {
    voltageData.clear();
    for (int i = 0; i < dataList.length; i++) {
      List<String> parts = dataList[i].split(', ');
      if (parts.length >= 3) {
        double voltage = double.tryParse(parts[2]) ?? 0;
        voltageData.add(FlSpot(i.toDouble(), voltage));
      }
    }
    voltageData = voltageData.reversed.toList();
    if (voltageData.length > maxDataPoints) {
      voltageData = voltageData.sublist(0, maxDataPoints);
    }
  }

  void onStatusChanged(String status) {
    setState(() {
      if (status == "Subscribed to Energizer/data") {
        statusText = "Connected";
      } else {
        statusText = "Disconnected";
      }
    });
  }

  Widget buildVoltageChart() {
    // Calculate the interval, ensuring it's never zero
    double interval =
        voltageData.length > 1 ? (voltageData.length / 5).ceil().toDouble() : 1;

    // Cap the y values to a maximum of 250
    final cappedVoltageData =
        voltageData.map((e) => FlSpot(e.x, e.y > 250 ? 250 : e.y)).toList();

    return Container(
      height: 300,
      padding: const EdgeInsets.only(
        top: 4,
        left: 10,
        right: 10,
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(
              show: true, drawVerticalLine: true, drawHorizontalLine: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 100,
                interval: interval, // Use the calculated interval
                getTitlesWidget: (value, meta) {
                  if (voltageData.isEmpty ||
                      value.toInt() >= voltageData.length)
                    return SizedBox.shrink();
                  String rawData =
                      receivedDataList[voltageData.length - 1 - value.toInt()];
                  List<String> parts = rawData.split(', ');
                  if (parts.length < 2) return SizedBox.shrink();
                  String dateStr = parts[0];
                  String timeStr = parts[1];
                  DateTime dateTime = DateFormat("HH:mm:ss").parse("$timeStr");
                  return Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Transform.rotate(
                      angle: -45 * 3.1415927 / 180,
                      child: Text(
                        DateFormat('HH:mm a').format(dateTime),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toStringAsFixed(0)}V',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: 0,
          maxX: voltageData.length > 1 ? voltageData.length.toDouble() - 1 : 1,
          minY: voltageData.isEmpty
              ? 0
              : (voltageData.map((e) => e.y).reduce((a, b) => a < b ? a : b) -
                      10)
                  .clamp(0, double.infinity),
          maxY: 250, // Set the maximum Y value to 250
          lineBarsData: [
            LineChartBarData(
              spots: cappedVoltageData, // Use the capped voltage data
              isCurved: true,
              color: Colors.yellow,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.yellow.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Center(
          child: Text(
            "Status: ${statusText}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 18,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: LoadingOverlay(
        isLoading: isLoading,
        child: Padding(
          // padding: const EdgeInsets.fromLTRB(40, 1.2 * kToolbarHeight, 40, 60),
          padding: const EdgeInsets.only(
            bottom: 40.0,
            top: 50.0,
            left: 10.0,
            right: 10.0,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
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
                Column(
                  children: [
                    buildVoltageChart(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 0.0),
                        itemCount: receivedDataList.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Card(
                              elevation: 2,
                              color: Colors.black.withOpacity(0.5),
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: FormattedListTile(
                                rawData: receivedDataList[index],
                                index: index,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormattedListTile extends StatelessWidget {
  final String rawData;
  int index;

  FormattedListTile({
    required this.rawData,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    List<String> dataParts = rawData.split(', ');

    if (dataParts.length < 4) {
      return const ListTile(
        title: Text(
          'Invalid data format',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    String date = dataParts[0];
    String time = dataParts[1];
    String voltage = dataParts[2];
    String relayStatus = dataParts[3] == '0' ? 'OFF' : 'ON';
    String pulseStatus = dataParts[4] != '0' ? "High" : "Low";

    DateTime dateTime = DateFormat("dd-MM-yyyy, HH:mm:ss")
        .parse("${dataParts[0]}, ${dataParts[1]}");

    String formattedDate = DateFormat("d MMMM yyyy").format(dateTime);
    String formattedTime = DateFormat("hh:mm:ss a").format(dateTime);

    return ListTile(
      title: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w300,
          ),
          children: [
            TextSpan(
              text: '$formattedDate, $formattedTime\n',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const TextSpan(text: 'Voltage: '),
            TextSpan(
              text: '$voltage V\n',
              style: const TextStyle(color: Colors.yellow),
            ),
            const TextSpan(text: 'Relay Status: '),
            TextSpan(
              text: relayStatus,
              style: TextStyle(
                color: relayStatus == 'ON' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const TextSpan(text: '\nPulse Status: '),
            TextSpan(
              text: pulseStatus,
              style: TextStyle(
                color: pulseStatus == 'High' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      leading: index == 0 ? const Icon(Icons.star, color: Colors.yellow) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
