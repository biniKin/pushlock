import 'package:flutter/material.dart';

class OverlayLockPage extends StatefulWidget {
  const OverlayLockPage({super.key, required this.appName, required this.packageName});

  final String packageName;
  final String appName;

  @override
  State<OverlayLockPage> createState() => _OverlayLockPageState();
}

class _OverlayLockPageState extends State<OverlayLockPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text("Time to do push ups!"),
      ),
    );
  }
}