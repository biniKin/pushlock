import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 80, color: Colors.white),
              const Text(
                "PushLock",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 100),
              const Text(
                "Time to do push ups!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "You should do push ups to unlock ${widget.appName}.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 18),
              ),
              const SizedBox(height: 30),
              SvgPicture.asset(
                "assets/icons/push-man.svg",
                height: 100,
                width: 200,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startPushups,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  "Start Push-ups",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
