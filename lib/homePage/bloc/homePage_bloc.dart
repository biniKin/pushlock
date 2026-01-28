import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pushlock/appStatModel.dart';
import 'package:pushlock/appUiModel.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:pushlock/homePage/bloc/homePage_state.dart';
import 'package:pushlock/locked_app.dart';
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
      // 1️⃣ Get raw data
      final installedApps = await installedAppsRepo.scanInstalledApps();
      final lockedApps = await lockedAppsRepo.getLockedApps();
      final appStats = await appStatsRepo.getTodayStats();

      // 2️⃣ Merge into UI models
      final List<Appuimodel> uiApps = buildUiApps(
        installedApps: installedApps,
        lockedApps: lockedApps,
        stats: appStats,
      );

      // 3️⃣ Sort by usage time
      uiApps.sort((a, b) => b.dailyUsageSeconds.compareTo(a.dailyUsageSeconds));

      // 4️⃣ Prepare dashboard data
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
