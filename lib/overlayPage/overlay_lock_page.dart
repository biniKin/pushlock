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
      backgroundColor: const Color.fromARGB(221, 24, 24, 24),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 80, color: Colors.white),
            Text("PushLock", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
            SizedBox(height: 100),
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
              "You should do push ups to unlock ${widget.appName}.",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            SizedBox(height: 30,),
            SvgPicture.asset("assets/icons/push-man.svg", height: 100, width: 200,),
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
