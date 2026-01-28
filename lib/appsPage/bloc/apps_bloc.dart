import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushlock/appsPage/bloc/apps_event.dart';
import 'package:pushlock/appsPage/bloc/apps_state.dart';
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
      final cachedApps = await appsRepository.getCachedApps();

      if (cachedApps.isNotEmpty) {
        emit(
          AppsLoaded(
            apps: cachedApps,
            fromCache: true,
          ),
        );
      } else {
        final scannedApps =
            await appsRepository.scanAndCacheApps();

        emit(
          AppsLoaded(
            apps: scannedApps,
            fromCache: false,
          ),
        );
      }
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
