import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pushlock/camerPage/camera_page.dart';
import 'package:pushlock/camerPage/unlockPage.dart';

late List<CameraDescription> cameras;

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const platform = MethodChannel('com.example.pushlock/navigation');
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // Listen for navigation events from native Android
    platform.setMethodCallHandler((call) async {
      if (call.method == 'navigateToUnlock') {
        navigatorKey.currentState?.pushNamed('/unlock');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CameraPage(),
        '/unlock': (context) => const Unlockpage(),

      },
    );
  }
}
