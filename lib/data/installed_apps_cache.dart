import 'package:hive/hive.dart';
import 'package:pushlock/model/appUiModel.dart';

class InstalledAppsCache {
  static const boxName = "installed_apps";

  // saveTocache
  Future<void> saveAppsToCache(List<Appuimodel> uiApps) async {
    final box = await Hive.openBox(boxName);

    await box.put("apps", uiApps.map((e) => e.toJson()).toList());
  }

  // getFromCache
  Future<List<Appuimodel>> loadCachedApps() async {
    final box = await Hive.openBox(boxName);
    final raw = box.get('apps');

    if (raw == null) return [];

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
