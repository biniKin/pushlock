import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_category.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/repositories/app_stats_repository.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';
import 'package:pushlock/repositories/locked_apps_repository.dart';
import 'package:pushlock/service/local_pushup_count_service.dart';


class AppsBloc extends Bloc<AppsEvent, AppsState> {
  final InstalledAppsRepository appsRepository;
  final LockedAppsRepository lockedAppsRepo;
  final AppStatsRepository appStatsRepo;
  final PushupSessionCache pushupSessionCache;
  final LocalPushupCountService localPushupCountService;

  AppsBloc({
    required this.appsRepository,
    required this.appStatsRepo,
    required this.localPushupCountService,
    required this.lockedAppsRepo,
    required this.pushupSessionCache
  }) : super(AppsInitial()) {
    on<LoadApps>(_onLoadApps);
    on<RefreshApps>(_onRefreshApps);
    on<CategoryChanged>(_onCategoryChanged);
    on<LockApp>(_onLockApp);
    on<UnlockApp>(_onUnlockapp);
  }

  Future _onLockApp(
    LockApp event,
    Emitter<AppsState> emit,
  ) async {
    if (state is! AppsLoaded) return;
    // get the current state
    final currentState = state as AppsLoaded;

    try {
      // call repo for lock the app (calls the method channel)
      final locked = await lockedAppsRepo.lockApp(event.app);
      locked ? print("app is locked successfully") : print("app is not locked");

      // save the push ups
      await pushupSessionCache.savePushUp(
        packageName: event.app.packageName,
        pushupCount: event.pushupCount,
      );

      // call cache update
      await appsRepository.updateCachedAppStatus(
        packageName: event.app.packageName,
        isLocked: true,
        timeoutSeconds: event.app.timeoutSeconds,
      );

      // update the app on the ui
      final updatedApps = currentState.apps.map((app) {
        if (app.packageName == event.app.packageName) {
          return app.copyWith(
            isLocked: true,
            // timeoutSeconds: event.app.timeoutSeconds,
          );
        }
        return app;
      }).toList();

      // 3️⃣ Recalculate counts
      final lockedCount = updatedApps.where((a) => a.isLocked).length;

      final updatedFilter = _applyCategoryFilter(updatedApps, event.selectedCategory);

      // emit
      emit(
        currentState.copyWith(
          apps: updatedApps,
          filteredApps: updatedFilter,
          selectedCategory: event.selectedCategory
        ),
      );
    } catch (e) {
      print("error: $e");
    }
  }

  Future _onUnlockapp(
    UnlockApp event,
    Emitter<AppsState> emit,
  ) async {
    if (state is! AppsLoaded) return;
    // get the current state
    final currentState = state as AppsLoaded;

    try {
      // call repo for lock the app (calls the method channel)
      await lockedAppsRepo.unlockApp(event.packageName);

      // call cache update
      await appsRepository.updateCachedAppStatus(
        packageName: event.packageName,
        isLocked: false,
      );

      // update the app on the ui
      final updatedApps = currentState.apps.map((app) {
        if (app.packageName == event.packageName) {
          return app.copyWith(isLocked: false);
        }
        return app;
      }).toList();

      // 3️⃣ Recalculate counts
      final lockedCount = updatedApps.where((a) => a.isLocked).length;

      final updatedFilter = _applyCategoryFilter(updatedApps, event.selectedCategory);

      // emit
      emit(
        currentState.copyWith(
          apps: updatedApps,
          filteredApps: updatedFilter,
          // lockedAppsCount: lockedCount,
          selectedCategory: event.selectedCategory
        ),
      );
    } catch (e) {
      print("error: $e");
    }
  }


  Future<void> _onLoadApps(LoadApps event, Emitter<AppsState> emit) async {
    emit(AppsLoading());

    try {
      // Always get fresh stats from Room database
      final cachedApps = await appsRepository.getCachedApps();

      List<Appuimodel> uiApps;
      if (cachedApps.isEmpty) {
        // No cache, do full scan
        uiApps = await appsRepository.scanAndCacheApps();
      } else {
        // Use cached app list but refresh stats from Room
        uiApps = await appsRepository.refreshStatsForCachedApps(cachedApps);
      }

      emit(
        AppsLoaded(
          apps: uiApps,
          filteredApps: uiApps, // Initially show all
          fromCache: cachedApps.isNotEmpty,
          selectedCategory: null, // null = "All"
        ),
      );
    } catch (e) {
      emit(AppsError(e.toString()));
    }
  }

  Future<void> _onRefreshApps(
    RefreshApps event,
    Emitter<AppsState> emit,
  ) async {
    // Keep current category selection during refresh
    String? currentCategory;
    if (state is AppsLoaded) {
      currentCategory = (state as AppsLoaded).selectedCategory;
    }

    emit(AppsLoading());

    try {
      // Force full scan and get fresh stats
      final apps = await appsRepository.scanAndCacheApps();

      // Apply current category filter if any
      final filteredApps = currentCategory == null
          ? apps
          : apps.where((app) => app.appCategory == currentCategory).toList();

      emit(
        AppsLoaded(
          apps: apps,
          filteredApps: filteredApps,
          fromCache: false,
          selectedCategory: currentCategory,
        ),
      );
    } catch (e) {
      emit(AppsError(e.toString()));
    }
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<AppsState> emit) {
    if (state is AppsLoaded) {
      final currentState = state as AppsLoaded;

      // Filter apps by category
      final filteredApps; 
      if(event.appCategory == null){
        filteredApps = currentState.apps;
      } else if(event.appCategory == "locked"){
        filteredApps = currentState.apps.where((app) => app.isLocked).toList();
      } else{
        filteredApps = currentState.apps
                .where((app) => app.appCategory == event.appCategory)
                .toList();
      }
          

      print("filtred apps: ${filteredApps.length}");

      emit(
        currentState.copyWith(
          filteredApps: filteredApps,
          selectedCategory: event.appCategory,
        ),
      );
    }
  }

  List<Appuimodel> _applyCategoryFilter(
    List<Appuimodel> apps,
    String? category,
  ) {
    if (category == null || category.isEmpty) return apps;
    return apps.where((a) => a.appCategory == category).toList();
  }

}
