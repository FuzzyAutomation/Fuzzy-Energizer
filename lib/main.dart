import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuzzyenergizer/pages/data_page.dart';
import 'package:fuzzyenergizer/pages/home_page.dart';
import 'package:fuzzyenergizer/pages/map_page.dart';
import 'package:fuzzyenergizer/services/mqtt_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.location,
    Permission.storage,
  ].request();

  if (statuses[Permission.location]!.isGranted) {
    print("Location permission granted");
  } else {
    print("Location permission denied");
  }

  if (statuses[Permission.storage]!.isGranted) {
    print("Storage permission granted");
  } else {
    print("Storage permission denied");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MQTTServiceProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MQTTServiceProvider with ChangeNotifier {
  late MQTTService _mqttService;
  String _status = 'Disconnected';
  String _lastMessage = '';

  MQTTServiceProvider() {
    _mqttService = MQTTService(
      (message) {
        _lastMessage = message;
        notifyListeners();
      },
      (status) {
        _status = status;
        notifyListeners();
      },
    );
    _connectMQTT();
  }

  void _connectMQTT() async {
    await _mqttService.connect();
    _mqttService.subscribe('Energizer/data');
  }

  String get status => _status;
  String get lastMessage => _lastMessage;

  void publishMessage(String topic, String message) {
    _mqttService.publish(topic, message);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuzzy Energizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainNavigation(),
    );
  }
}

class CurvedBottomNavBarShape extends ShapeBorder {
  final double radius;

  CurvedBottomNavBarShape({this.radius = 30.0});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..moveTo(rect.left, rect.top + radius)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    DataPage(),
    MapPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 16, 30).withOpacity(0.7),
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 0, 16, 30).withOpacity(0.8),
              const Color.fromARGB(255, 0, 16, 30).withOpacity(0.6),
            ],
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              const Color.fromARGB(255, 0, 16, 30).withOpacity(0.5),
            ],
          ),
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(
            shape: CurvedBottomNavBarShape(),
          ),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor:
                const Color.fromARGB(255, 0, 16, 30).withOpacity(0.5),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.data_usage),
                label: 'Data',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: 'Map',
              ),
            ],
            selectedItemColor: Colors.amber,
            unselectedItemColor: Colors.white60,
          ),
        ),
      ),
    );
  }
}
