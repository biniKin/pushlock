import 'dart:async';

import 'package:pushlock/service/appLockService.dart';
import 'package:pushlock/model/locked_app.dart';

class LockedAppsRepository {
  final AppLockService _appLockService = AppLockService();


  final StreamController<List<LockedApp>> _lockedAppsController = 
    StreamController<List<LockedApp>>.broadcast();

  Stream<List<LockedApp>> get lockedAppsStream => _lockedAppsController.stream;

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
      final result = await _appLockService.addLockedApp(app);
      if(result){
        await _emitLockedApps();
      }
      return result;

    } catch (e) {
      print("Error locking app: $e");
      return false;
    }
  }

  Future<bool> unlockApp(String packageName) async {
    try {
      final res = await _appLockService.removeLockedApp(packageName);
      if(res){
        await _emitLockedApps();

      }
      return res;
    } catch (e) {
      print("Error unlocking app: $e");
      return false;
    }
  }

  Future<bool> updateLockedApp(LockedApp app) async {
    try {
      final result = await _appLockService.updateLockedApp(app);
      if(result) await _emitLockedApps();

      return result;
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

  Future<void> _emitLockedApps() async {
    final apps = await getLockedApps();
    _lockedAppsController.add(apps);
  }

  Future<void> loadInitialState() async {
    await _emitLockedApps();
  }

  void dispose(){
    _lockedAppsController.close();
  }


}
