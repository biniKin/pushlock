import 'package:pushlock/model/appUiModel.dart';

abstract class HomepageState {}

class HomepageInitial extends HomepageState {}

class HomepageLoading extends HomepageState {}

class HomepageLoaded extends HomepageState {
  final List<Appuimodel> chartApps;

  // Summary
  final int lockedAppsCount;
  final int totalAppsCount;

  // List of most used apps
  final List<Appuimodel> mostUsedApps;

  HomepageLoaded({
    required this.chartApps,
    required this.lockedAppsCount,
    required this.totalAppsCount,
    required this.mostUsedApps,
  });

  HomepageLoaded copyWith({
    List<Appuimodel>? chartApps,
    int? lockedAppsCount,
    int? totalAppsCount,
    List<Appuimodel>? mostUsedApps,

  }){
    return HomepageLoaded(
      chartApps: chartApps ?? this.chartApps, 
      lockedAppsCount: lockedAppsCount ?? this.lockedAppsCount, 
      totalAppsCount: totalAppsCount ?? this.totalAppsCount, 
      mostUsedApps: mostUsedApps ?? this.mostUsedApps,
    );
  }
}

class HomepageError extends HomepageState {
  final String message;

  HomepageError(this.message);
}
