import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:pushlock/model/appStatModel.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/data/installed_apps_cache.dart';
import 'package:pushlock/model/locked_app.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';

class InstalledAppsRepository {
  final InstalledAppsCache cache;
  final LockedAppsRepository lockedAppsRepo;
  final AppStatsRepository appStatsRepo;

  InstalledAppsRepository(this.cache, this.appStatsRepo, this.lockedAppsRepo);

  /// RAW scan (plugin only)
  Future<List<AppInfo>> scanInstalledApps() async {
    try {
      return await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
    } catch (e) {
      print("Error scanning apps: $e");
      return [];
    }
  }

  /// Convert plugin apps → UI models
  List<Appuimodel> _mapToUiModels({
    required List<AppInfo> apps,
    required List<LockedApp> lockedApps,
    required List<Appstatmodel> stats,
  }) {
    final lockedAppsMap = {for (final app in lockedApps) app.packageName: app};

    final statsMap = {for (final stat in stats) stat.packageName: stat};

    return apps.map((installedApp) {
      final packageName = installedApp.packageName!;
      final lockedApp = lockedAppsMap[packageName];
      final stat = statsMap[packageName];

      return Appuimodel(
        packageName: packageName,
        appName: installedApp.name!,
        icon: installedApp.icon,
        dailyUsageSeconds: stat != null
            ? int.tryParse(stat.dailyUsageTime) ?? 0
            : 0,
        isLocked: lockedApp != null,
        timeoutSeconds: lockedApp?.timeoutSeconds,
        versionName: installedApp.versionName!,
      );
    }).toList();
  }

  /// Load cached apps
  Future<List<Appuimodel>> getCachedApps() async {
    return await cache.loadCachedApps();
  }

  Future<void> updateCachedAppStatus({
    required String packageName, required bool isLocked,  int? timeoutSeconds
    }) async{
    await cache.updateCachedAppStatus(packageName: packageName, isLocked: isLocked, timeoutSeconds: timeoutSeconds);
  }
  /// Scan → merge → cache
  Future<List<Appuimodel>> scanAndCacheApps() async {
    // 1. Scan installed apps
    final installedApps = await scanInstalledApps();

    // 2. Load locked apps
    final lockedApps = await lockedAppsRepo.getLockedApps();

    // 3. Load today's stats
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final stats = await appStatsRepo.getAppsStatForDay(today);

    // 4. Merge
    final uiApps = _mapToUiModels(
      apps: installedApps,
      lockedApps: lockedApps,
      stats: stats,
    );

    // 5. Cache
    await cache.saveAppsToCache(uiApps);

    return uiApps;
  }
}
