import 'package:flutter/services.dart';
import 'package:pushlock/model/locked_app.dart';

class AppLockService {
  static const platform = MethodChannel("com.example.pushlock/app_lock");

  Future<bool> canDrawOverlay() async {
    final result = await platform.invokeMethod("canDrawOverLay");
    return result ?? false;
  }

  Future<bool> hasUsageAccess() async {
    final res = await platform.invokeMethod("hasUsageAccess");
    return res ?? false;
  }

  Future<void> navigateToOverlaySettings() async {
    await platform.invokeMethod("requestOverlayPermission");
  }

  Future<void> navigateToUsageSettings() async {
    await platform.invokeMethod("requestUsagePermission");
  }

  Future<void> navigateToBatterySettings() async {
    await platform.invokeMethod("requestBatteryOptimization");
  }

  Future<bool> hasBatteryOptimization() async {
    final res = await platform.invokeMethod("hasBatteryOptimization");
    return res ?? false;
  }

  Future<void> startAppLockService() async {
    await platform.invokeMethod("startAppLockService");
  }

  // addLockedApp: sends packageName, appName, timeoutSeconds, isStrict. return success/failure
  Future<bool> addLockedApp(LockedApp app) async {
    try {
      final result = await platform.invokeMethod<bool>("addLockedApp", {
        'packageName': app.packageName,
        'appName': app.appName,
        'isStrict': app.isStrict,
        'timeoutSeconds': app.timeoutSeconds,
      });

      return result ?? false;
    } catch (e) {
      print("error on add locked app method channel: $e");
      return false;
    }
  }

  // removeLockedApp: packageName. return success/failure
  Future<bool> removeLockedApp(String packageName) async {
    try {
      final result = await platform.invokeMethod<bool>(
        "removeLockedApp",
        packageName,
      );

      return result ?? false;
    } catch (e) {
      print("error on removelocked app: $e");
      return false;
    }
  }

  // getLockedApps: List of lockedapps(json)
  Future<List<LockedApp>?> getLockedApps() async {
    try {
      final apps = await platform.invokeMethod("getLockedApps");
      if (apps != null && apps is List) {
        return LockedApp.fromJsonList(apps);
      } else {
        return [];
      }
    } catch (e) {
      print("error on  getting locked apps: $e");
      return [];
    }
  }

  // updateLockedApps
  Future<bool> updateLockedApp(LockedApp app) async {
    try {
      final result = await platform.invokeMethod<bool>("updateLockedApp", {
        'packageName': app.packageName,
        'appName': app.appName,
        'isStrict': app.isStrict,
        'timeoutSeconds': app.timeoutSeconds,
      });

      return result ?? false;
    } catch (e) {
      print("error on add locked app method channel: $e");
      return false;
    }
  }

  // isAppLocked: packageName
  Future<bool> isAppLocked(String packageName) async {
    try {
      final isLocked = await platform.invokeMethod<bool>(
        "isAppLocked",
        packageName,
      );
      return isLocked ?? false;
    } catch (e) {
      print("error on checking if app is locked: $e");
      return false;
    }
  }

  // unlockApp: packageName - resets timer and removes overlay
  Future unlockApp(String packageName) async {
    try {
      // final result = await platform.invokeMethod<bool>(
      //   "unlockApp",
      //   packageName,
      // );

      MethodChannel(
        'overlay_channel',
      ).invokeMethod('unlock', {'packageName': packageName});

      // return result ?? false;
    } catch (e) {
      print("error on unlocking app: $e");
      return false;
    }
  }
}
