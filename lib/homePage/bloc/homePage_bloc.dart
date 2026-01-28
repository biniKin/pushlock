import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pushlock/model/appStatModel.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:pushlock/homePage/bloc/homePage_state.dart';
import 'package:pushlock/model/locked_app.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final InstalledAppsRepository installedAppsRepo;
  final LockedAppsRepository lockedAppsRepo;
  final AppStatsRepository appStatsRepo;

  HomepageBloc({
    required this.installedAppsRepo,
    required this.lockedAppsRepo,
    required this.appStatsRepo,
  }) : super(HomepageInitial()) {
    on<LoadHomepageData>(_onLoadHomepage);
    on<RefreshHomepageData>(_onLoadHomepage);
  }

  Future<void> _onLoadHomepage(
    HomepageEvent event,
    Emitter<HomepageState> emit,
  ) async {
    emit(HomepageLoading());

    try {
      List<Appuimodel> uiApps;

      // Check if this is a refresh event
      if (event is RefreshHomepageData) {
        // Force scan and cache
        uiApps = await installedAppsRepo.scanAndCacheApps();
      } else {
        // Try to load from cache first
        final cachedApps = await installedAppsRepo.getCachedApps();

        if (cachedApps.isEmpty) {
          // No cache, scan and cache
          uiApps = await installedAppsRepo.scanAndCacheApps();
        } else {
          // Use cached data
          uiApps = cachedApps;
        }
      }

      // Sort by usage time
      uiApps.sort((a, b) => b.dailyUsageSeconds.compareTo(a.dailyUsageSeconds));

      // Prepare dashboard data
      final chartApps = uiApps.take(4).toList();
      final lockedCount = uiApps.where((app) => app.isLocked).length;
      final totalCount = uiApps.length;

      emit(
        HomepageLoaded(
          chartApps: chartApps,
          lockedAppsCount: lockedCount,
          totalAppsCount: totalCount,
          mostUsedApps: uiApps,
        ),
      );
    } catch (e) {
      emit(HomepageError(e.toString()));
    }
  }

  List<Appuimodel> buildUiApps({
    required List<AppInfo> installedApps,
    required List<LockedApp> lockedApps,
    required List<Appstatmodel> stats,
  }) {
    // Create a map for quick lookup
    final lockedAppsMap = {for (var app in lockedApps) app.packageName: app};
    final statsMap = {for (var stat in stats) stat.packageName: stat};

    // Build UI models
    return installedApps.map((installedApp) {
      final packageName = installedApp.packageName ?? '';
      final lockedApp = lockedAppsMap[packageName];
      final stat = statsMap[packageName];

      return Appuimodel(
        packageName: packageName,
        appName: installedApp.name ?? 'Unknown',
        icon: installedApp.icon,
        dailyUsageSeconds: stat != null
            ? int.tryParse(stat.dailyUsageTime) ?? 0
            : 0,
        isLocked: lockedApp != null,
        timeoutSeconds: lockedApp?.timeoutSeconds,
        versionName: installedApp.versionName ?? '',
      );
    }).toList();
  }
}
