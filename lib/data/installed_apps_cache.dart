import 'package:hive/hive.dart';
import 'package:pushlock/model/appUiModel.dart';

class InstalledAppsCache {
  static const boxName = "installed_apps";

  // saveTocache
  Future<void> saveAppsToCache(List<Appuimodel> uiApps) async {
    final box = await Hive.openBox(boxName);
    print("about to save apps to cache");

    await box.put("apps", uiApps.map((e) => e.toJson()).toList());
  }

  Future<void> updateCachedAppStatus({
    required String packageName,
    required bool isLocked,
    int? timeoutSeconds,
  }) async {
    final box = await Hive.openBox(boxName);
    final raw = box.get('apps');

    if (raw == null) return;

    final apps = (raw as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final updatedApps = apps.map((app) {
      if (app['packageName'] == packageName) {
        return {
          ...app,
          'isLocked': isLocked,
          'timeoutSeconds': timeoutSeconds,
        };
      }
      return app;
    }).toList();

    await box.put('apps', updatedApps);
  }


  // getFromCache
  Future<List<Appuimodel>> loadCachedApps() async {
    print("about to get cached apps");
    final box = await Hive.openBox(boxName);
    final raw = box.get('apps');

    if (raw == null){
      print("box for cached is empty");
      return [];
    }

    return (raw as List)
        .map((e) => Appuimodel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // deleteFromCache
  Future<void> clearCachedApps() async {
    final box = await Hive.openBox(boxName);
    await box.delete('apps');
  }
}
