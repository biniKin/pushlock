import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/app_category.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';

class AppsBloc extends Bloc<AppsEvent, AppsState> {
  final InstalledAppsRepository appsRepository;

  AppsBloc(this.appsRepository) : super(AppsInitial()) {
    on<LoadApps>(_onLoadApps);
    on<RefreshApps>(_onRefreshApps);
    on<CategoryChanged>(_onCategoryChanged);
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
    AppCategory? currentCategory;
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
      final filteredApps = event.appCategory == null
          ? currentState
                .apps // Show all
          : currentState.apps
                .where((app) => app.appCategory == event.appCategory)
                .toList();

      emit(
        currentState.copyWith(
          filteredApps: filteredApps,
          selectedCategory: event.appCategory,
        ),
      );
    }
  }
}
