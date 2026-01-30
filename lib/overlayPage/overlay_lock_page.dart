import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OverlayLockPage extends StatefulWidget {
  const OverlayLockPage({
    super.key,
    required this.appName,
    required this.packageName,
  });

  final String packageName;
  final String appName;

  @override
  State<OverlayLockPage> createState() => _OverlayLockPageState();
}

class _OverlayLockPageState extends State<OverlayLockPage> {
  static const platform = MethodChannel('overlay_channel');

  Future<void> _startPushups() async {
    try {
      // Tell Kotlin to open the main app to the camera page
      await platform.invokeMethod('openMainApp', {
        'packageName': widget.packageName,
        'appName': widget.appName,
      });
    } catch (e) {
      print('Error opening main app: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Time to do push ups!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              widget.appName,
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startPushups,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text("Start Push-ups", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
