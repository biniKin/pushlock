import 'package:flutter/material.dart';
import 'package:pushlock/homePage.dart';
import 'package:pushlock/lock_overlay.dart' as overlay;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

@pragma("vm:entry-point")
void overlayMain() {
  overlay.overLayMain();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const Homepage(),
    );
  }
}
