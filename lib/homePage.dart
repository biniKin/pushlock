import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pushlock/foreground_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<AppInfo> applists = [];
  bool _isOverlayActive = false;

  Future<List<AppInfo>> getApps() async {
    List<AppInfo> intalledApps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      withIcon: true,
    );
    setState(() {
      applists = intalledApps;
    });
    return intalledApps;
  }

  void launchOverlay() async {
    if (_isOverlayActive) {
      print("Overlay already active, skipping");
      return;
    }

    print("on launch overlay function");
    final hasPermission = await FlutterOverlayWindow.isPermissionGranted();
    if (!hasPermission) {
      print("no permission");
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    // _isOverlayActive = true;
    await FlutterOverlayWindow.showOverlay(
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
      enableDrag: false,
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      overlayTitle: "PushLock",
      overlayContent: "Lock Screen",
    );
  }

  void closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  void openAccessibilitySettings() async {
    bool isEnabled =
        await FlutterAccessibilityService.isAccessibilityPermissionEnabled();

    if (!isEnabled) {
      final intent = AndroidIntent(
        action: 'android.settings.ACCESSIBILITY_SETTINGS',
      );
      intent.launch();
    } else {
      print("Accessbility permission granted!");
    }
  }

  @override
  void initState() {
    super.initState();

    // openAccessibilitySettings();
    // ForegroundService.foregroundApps.listen((packageName) {
    //   print("Opened app: $packageName");

    //   // Ignore our own app
    //   if (packageName == "com.example.pushlock") {
    //     print("Our own app, skipping overlay");
    //     _isOverlayActive = false;
    //     return;
    //   }

    //   // Example lock condition
    //   if (packageName == "com.instagram.android") {
    //     // show lock screen
    //     print("...........Instagram is opened................");
    //     launchOverlay();
    //   } else {
    //     closeOverlay();
    //   }
    // });
    // getApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView.builder(
            itemCount: applists.length,
            itemBuilder: (context, index) {
              final app = applists[index];
              // print("app name: ${app.name}");
              // print("package name: ${app.packageName}");
              // print("version name: ${app.versionName}");
              // print("version code: ${app.versionCode}");
              // print("installed time: ${app.installedTimestamp}");

              return ListTile(
                contentPadding: EdgeInsets.all(10),
                leading: app.icon != null
                    ? Image.memory(app.icon!)
                    : Icon(Icons.apps),
                title: Text(app.name),
              );
            },
          ),
        ),
      ),
    );
  }
}
