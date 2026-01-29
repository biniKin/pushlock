import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_info.dart';
import 'package:pushlock/data/installed_apps_cache.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
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
  final PushupSessionCache pushupSessionCache;
  

  HomepageBloc({
    required this.installedAppsRepo,
    required this.lockedAppsRepo,
    required this.appStatsRepo,
    required this.pushupSessionCache
  }) : super(HomepageInitial()) {
    on<LoadHomepageData>(_onLoadHomepage);
    on<RefreshHomepageData>(_onLoadHomepage);
    on<LockAppRequested>(_onLockAppRequest);
    on<UnlockAppRequested>(_onUnlockAppRequest);
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

  Future _onLockAppRequest(
    LockAppRequested event,
    Emitter<HomepageState> emit,
  ) async{
    if(state is !HomepageLoaded) return;
    // get the current state
    final currentState = state as HomepageLoaded;

    try{

    
      // call repo for lock the app (calls the method channel)
      final locked = await lockedAppsRepo.lockApp(event.app);
      locked ? print("app is locked successfully") : print("app is not locked");


      // save the push ups
      await pushupSessionCache.savePushUp(packageName: event.app.packageName, pushupCount: event.pushupscount);

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
    }catch(e){
      print("error: ${e}");
    }
  }

  Future _onUnlockAppRequest(
    UnlockAppRequested event,
    Emitter<HomepageState> emit
  )async{
     if(state is !HomepageLoaded) return;
    // get the current state
    final currentState = state as HomepageLoaded;

    try{

    
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
          return app.copyWith(
            isLocked: false,
            
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
    }catch(e){
      print("error: ${e}");
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
