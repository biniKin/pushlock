import 'package:pushlock/appLockService.dart';
import 'package:pushlock/locked_app.dart';

class LockedAppsRepository {
  final AppLockService _appLockService = AppLockService();

  Future<List<LockedApp>> getLockedApps() async {
    try {
      final apps = await _appLockService.getLockedApps();
      return apps ?? [];
    } catch (e) {
      print("Error getting locked apps: $e");
      return [];
    }
  }

  Future<bool> lockApp(LockedApp app) async {
    try {
      return await _appLockService.addLockedApp(app);
    } catch (e) {
      print("Error locking app: $e");
      return false;
    }
  }

  Future<bool> unlockApp(String packageName) async {
    try {
      return await _appLockService.removeLockedApp(packageName);
    } catch (e) {
      print("Error unlocking app: $e");
      return false;
    }
  }

  Future<bool> updateLockedApp(LockedApp app) async {
    try {
      return await _appLockService.updateLockedApp(app);
    } catch (e) {
      print("Error updating locked app: $e");
      return false;
    }
  }

  Future<bool> isAppLocked(String packageName) async {
    try {
      return await _appLockService.isAppLocked(packageName);
    } catch (e) {
      print("Error checking if app is locked: $e");
      return false;
    }
  }
}
