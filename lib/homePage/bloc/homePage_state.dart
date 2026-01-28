import 'package:pushlock/appUiModel.dart';

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
}

class HomepageError extends HomepageState {
  final String message;

  HomepageError(this.message);
}
