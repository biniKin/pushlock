import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/model/appStatModel.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/homePage/bloc/homePage_event.dart';
import 'package:pushlock/homePage/bloc/homePage_state.dart';
import 'package:pushlock/model/locked_app.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';
import 'package:pushlock/service/local_pushup_count_service.dart';

class HomepageBloc extends Bloc<HomepageEvent, HomepageState> {
  final InstalledAppsRepository installedAppsRepo;
  final LockedAppsRepository lockedAppsRepo;
  final AppStatsRepository appStatsRepo;
  final PushupSessionCache pushupSessionCache;
  final LocalPushupCountService localPushupCountService;

  HomepageBloc({
    required this.installedAppsRepo,
    required this.lockedAppsRepo,
    required this.appStatsRepo,
    required this.pushupSessionCache,
    required this.localPushupCountService
  }) : super(HomepageInitial()) {
    on<LoadHomepageData>(_onLoadHomepage);
    on<RefreshHomepageData>(_onRefHomepage);
    on<LockAppRequested>(_onLockAppRequest);
    on<UnlockAppRequested>(_onUnlockAppRequest);
  }

  
  Future<void> _onRefHomepage(
    HomepageEvent event,
    Emitter<HomepageState> emit,
  ) async {
    // emit(HomepageLoading());

    try {
      List<Appuimodel> uiApps;

      // Check if this is a refresh event
      if (event is RefreshHomepageData) {
        
        // Force full scan and cache
        uiApps = await installedAppsRepo.scanAndCacheApps();
      } else {
        // Hybrid approach: Try to load from cache first
        final cachedApps = await installedAppsRepo.getCachedApps();

        if (cachedApps.isEmpty) {
          print("cached apps are empty.");
          // No cache, do full scan
          uiApps = await installedAppsRepo.scanAndCacheApps();
          print("ui apps found: ${uiApps.length}");
        } else {
          print("cached apps are not empty");
          // Use cached app list but refresh stats
          uiApps = await installedAppsRepo.refreshStatsForCachedApps(
            cachedApps,
          );
          print("ui apps found on else bloc: ${uiApps.length}");
        }
      }

      // Sort by usage time
      uiApps.sort((a, b) => b.dailyUsageSeconds.compareTo(a.dailyUsageSeconds));

      // Prepare dashboard data
      final chartApps = uiApps.take(4).toList();
      final lockedCount = uiApps.where((app) => app.isLocked).length;
      final totalCount = uiApps.length;

      // get it from shared pref
      final totalpushups = localPushupCountService.getPushupCountLocally();

      emit(
        HomepageLoaded(
          chartApps: chartApps,
          lockedAppsCount: lockedCount,
          totalAppsCount: totalCount,
          mostUsedApps: uiApps,
          totalPushups: totalpushups
        ),
      );
    } catch (e) {
      emit(HomepageError(e.toString()));
      print("error on loading apps: $e");
    }
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
        
        // Force full scan and cache
        uiApps = await installedAppsRepo.scanAndCacheApps();
      } else {
        // Hybrid approach: Try to load from cache first
        final cachedApps = await installedAppsRepo.getCachedApps();

        if (cachedApps.isEmpty) {
          print("cached apps are empty.");
          // No cache, do full scan
          uiApps = await installedAppsRepo.scanAndCacheApps();
          print("ui apps found: ${uiApps.length}");
        } else {
          print("cached apps are not empty");
          // Use cached app list but refresh stats
          uiApps = await installedAppsRepo.refreshStatsForCachedApps(
            cachedApps,
          );
          print("ui apps found on else bloc: ${uiApps.length}");
        }
      }

      // Sort by usage time
      uiApps.sort((a, b) => b.dailyUsageSeconds.compareTo(a.dailyUsageSeconds));

      // Prepare dashboard data
      final chartApps = uiApps.take(4).toList();
      final lockedCount = uiApps.where((app) => app.isLocked).length;
      final totalCount = uiApps.length;

      // get it from shared pref
      final totalpushups = localPushupCountService.getPushupCountLocally();

      emit(
        HomepageLoaded(
          chartApps: chartApps,
          lockedAppsCount: lockedCount,
          totalAppsCount: totalCount,
          mostUsedApps: uiApps,
          totalPushups: totalpushups
        ),
      );
    } catch (e) {
      emit(HomepageError(e.toString()));
      print("error on loading apps: $e");
    }
  }

  Future _onLockAppRequest(
    LockAppRequested event,
    Emitter<HomepageState> emit,
  ) async {
    if (state is! HomepageLoaded) return;
    // get the current state
    final currentState = state as HomepageLoaded;

    try {
      // call repo for lock the app (calls the method channel)
      final locked = await lockedAppsRepo.lockApp(event.app);
      locked ? print("app is locked successfully") : print("app is not locked");

      // save the push ups
      await pushupSessionCache.savePushUp(
        packageName: event.app.packageName,
        pushupCount: event.pushupscount,
      );

      // call cache update
      await installedAppsRepo.updateCachedAppStatus(
        packageName: event.app.packageName,
        isLocked: true,
        timeoutSeconds: event.app.timeoutSeconds,
      );

      // update the app on the ui
      final updatedApps = currentState.mostUsedApps.map((app) {
        if (app.packageName == event.app.packageName) {
          return app.copyWith(
            isLocked: true,
            timeoutSeconds: event.app.timeoutSeconds,
          );
        }
        return app;
      }).toList();

      // 3️⃣ Recalculate counts
      final lockedCount = updatedApps.where((a) => a.isLocked).length;

      // emit
      emit(
        currentState.copyWith(
          mostUsedApps: updatedApps,
          lockedAppsCount: lockedCount,
        ),
      );
    } catch (e) {
      print("error: $e");
    }
  }

  Future _onUnlockAppRequest(
    UnlockAppRequested event,
    Emitter<HomepageState> emit,
  ) async {
    if (state is! HomepageLoaded) return;
    // get the current state
    final currentState = state as HomepageLoaded;

    try {
      // call repo for lock the app (calls the method channel)
      await lockedAppsRepo.unlockApp(event.packageName);

      // call cache update
      await installedAppsRepo.updateCachedAppStatus(
        packageName: event.packageName,
        isLocked: false,
      );

      // update the app on the ui
      final updatedApps = currentState.mostUsedApps.map((app) {
        if (app.packageName == event.packageName) {
          return app.copyWith(isLocked: false);
        }
        return app;
      }).toList();

      // 3️⃣ Recalculate counts
      final lockedCount = updatedApps.where((a) => a.isLocked).length;

      // emit
      emit(
        currentState.copyWith(
          mostUsedApps: updatedApps,
          lockedAppsCount: lockedCount,
        ),
      );
    } catch (e) {
      print("error: $e");
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
        dailyUsageSeconds: stat != null ? stat.dailyUsageTime ?? 0 : 0,
        isLocked: lockedApp != null,
        timeoutSeconds: lockedApp?.timeoutSeconds,
        versionName: installedApp.versionName ?? '',
        appCategory: installedApp.category.name
      );
    }).toList();
  }
}
