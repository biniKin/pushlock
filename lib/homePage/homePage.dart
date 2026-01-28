import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pushlock/service/appLockService.dart';
import 'package:pushlock/model/locked_app.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<AppInfo> applists = [];
  Set<String> lockedPackages = {}; // Track locked app packages
  final AppLockService _appLockService = AppLockService();

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

  Future<void> loadLockedApps() async {
    final lockedApps = await _appLockService.getLockedApps();
    if (lockedApps != null) {
      setState(() {
        lockedPackages = lockedApps.map((app) => app.packageName).toSet();
      });
    }
  }

  Future<void> toggleAppLock(AppInfo app, bool isLocked) async {
    if (isLocked) {
      // Add app to locked list with default timeout of 5 seconds
      final lockedApp = LockedApp(
        packageName: app.packageName,
        appName: app.name,
        isStrict: false,
        timeoutSeconds: 5,
      );
      final success = await _appLockService.addLockedApp(lockedApp);
      if (success) {
        setState(() {
          lockedPackages.add(app.packageName);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${app.name} locked')));
        }
      }
    } else {
      // Remove app from locked list
      final success = await _appLockService.removeLockedApp(app.packageName);
      if (success) {
        setState(() {
          lockedPackages.remove(app.packageName);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${app.name} unlocked')));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getApps();
    loadLockedApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lock Apps'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SafeArea(
        child: applists.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: applists.length,
                itemBuilder: (context, index) {
                  final app = applists[index];
                  final isLocked = lockedPackages.contains(app.packageName);

                  return ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: app.icon != null
                        ? Image.memory(app.icon!)
                        : const Icon(Icons.apps),
                    title: Text(app.name),
                    subtitle: Text(app.packageName),
                    trailing: Switch(
                      value: isLocked,
                      onChanged: (value) {
                        toggleAppLock(app, value);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
