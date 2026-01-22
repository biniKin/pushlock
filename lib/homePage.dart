import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pushlock/foreground_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<AppInfo> applists = [];
  
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

  void openAccessibilitySettings(){
    const intent = AndroidIntent(
      action: 'android.settings.ACCESSIBILITY_SETTINGS',
    );
    intent.launch();
  }

  @override
  void initState() {
    
    super.initState();
    
    openAccessibilitySettings();
    ForegroundService.foregroundApps.listen((packageName) {
      print("Opened app: $packageName");

      // Example lock condition
      if (packageName == "com.instagram.android") {
        // show lock screen
        print("...........Instagram is opened................");
      }
    });
    // getApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView.builder(
            itemCount: applists.length,
            itemBuilder: (context, index){
              final app = applists[index];
              // print("app name: ${app.name}");
              // print("package name: ${app.packageName}");
              // print("version name: ${app.versionName}");
              // print("version code: ${app.versionCode}");
              // print("installed time: ${app.installedTimestamp}");
        
              return ListTile(
                contentPadding: EdgeInsets.all(10),
                leading: app.icon != null ? Image.memory(app.icon!) : Icon(Icons.apps),
                title: Text(app.name),
              );
            }
          ),
        ),
      ),
    );
  }
}