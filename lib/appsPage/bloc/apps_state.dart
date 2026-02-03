import 'package:installed_apps/app_category.dart';
import 'package:pushlock/model/appUiModel.dart';

abstract class AppsState {}

class AppsInitial extends AppsState {}

class AppsLoading extends AppsState {}

class AppsLoaded extends AppsState {
  final List<Appuimodel> apps;
  final List<Appuimodel> filteredApps;
  final bool fromCache;
  final String? selectedCategory;

  AppsLoaded({
    required this.apps,
    required this.filteredApps,
    required this.fromCache,
    this.selectedCategory,
  });

  AppsLoaded copyWith({
    List<Appuimodel>? apps,
    List<Appuimodel>? filteredApps,
    bool? fromCache,
    String? selectedCategory,
  }) {
    return AppsLoaded(
      apps: apps ?? this.apps,
      filteredApps: filteredApps ?? this.filteredApps,
      fromCache: fromCache ?? this.fromCache,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class AppsError extends AppsState {
  final String message;

  AppsError(this.message);
}
