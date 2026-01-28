import 'package:hive/hive.dart';
import 'package:pushlock/appUiModel.dart';

class InstalledAppsCache{
  static const boxName = "installed_apps";
  // saveTocache
  Future saveAppsToCache(List<Appuimodel> uiApps) async {
    final box = await Hive.openBox(boxName);

    box.put(
      "apps", 
      uiApps.map((e)=> e.toJson()).toList()
    );

  }

  // getFromCache
  Future loadCachedApps() async {
    final box = await Hive.openBox(boxName);
    final raw = box.get('apps');

    if (raw == null) return [];

    return (raw as List)
        .map((e) => Appuimodel.fromJson(
              Map<String, dynamic>.from(e),
            ))
        .toList();
  }

  // deleteFromCache
  Future clearCachedApps() async {
    final box = await Hive.openBox(boxName);
    await box.delete('apps');
  }

  
}