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

  @override
  void initState() {
    super.initState();
    debugPrint(
      "OVERLAY_PAGE: initState called with packageName=${widget.packageName}, appName=${widget.appName}",
    );
  }

  Future<void> _startPushups() async {
    try {
      debugPrint("OVERLAY_PAGE: Start pushups button pressed");

      // Call Kotlin to remove overlay and open main app with camera page
      await platform.invokeMethod('openMainApp', {
        'packageName': widget.packageName,
        'appName': widget.appName,
      });
    } catch (e) {
      debugPrint('OVERLAY_PAGE: Error calling openMainApp: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      "OVERLAY_PAGE: Building with packageName=${widget.packageName}, appName=${widget.appName}",
    );
    return Material(
      color: Colors.black87,
      
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
      
    );
  }
}
