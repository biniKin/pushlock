import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppsRepository {
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true, // excludeSystemApps
        withIcon: true, // withIcon
      );
      return apps;
    } catch (e) {
      print("Error getting installed apps: $e");
      return [];
    }
  }
}
