import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
import 'package:pushlock/model/appUiModel.dart';
import 'package:pushlock/repositories/installed_apps_repository.dart';

class AppsBloc extends Bloc<AppsEvent, AppsState> {
  final InstalledAppsRepository appsRepository;


  AppsBloc(this.appsRepository) : super(AppsInitial()) {
    on<LoadApps>(_onLoadApps);
    on<RefreshApps>(_onRefreshApps);
  }
  

  Future<void> _onLoadApps(
    LoadApps event,
    Emitter<AppsState> emit,
  ) async {
    emit(AppsLoading());

    try {
      List<Appuimodel> uiApps;

      // Check if this is a refresh event
      if (event is RefreshApps) {
        // Force full scan and cache
        uiApps = await appsRepository.scanAndCacheApps();
      } else {
        // Hybrid approach: Try to load from cache first
        final cachedApps = await appsRepository.getCachedApps();

        if (cachedApps.isEmpty) {
          // No cache, do full scan
          uiApps = await appsRepository.scanAndCacheApps();
        } else {
          // Use cached app list but refresh stats
          uiApps = await appsRepository.refreshStatsForCachedApps(
            cachedApps,
          );
        }
      }


        emit(
          AppsLoaded(
            apps: uiApps,
            fromCache: true,
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
    emit(AppsLoading());

    try {
      final apps =
          await appsRepository.scanAndCacheApps();

      emit(
        AppsLoaded(
          apps: apps,
          fromCache: false,
        ),
      );
    } catch (e) {
      emit(AppsError(e.toString()));
    }
  }
}
