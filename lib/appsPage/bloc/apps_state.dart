import 'package:pushlock/model/appUiModel.dart';

abstract class AppsState {}

class AppsInitial extends AppsState {}

class AppsLoading extends AppsState {}

class AppsLoaded extends AppsState {
  final List<Appuimodel> apps;
  final bool fromCache;

  AppsLoaded({
    required this.apps,
    required this.fromCache,
  });
}

class AppsError extends AppsState {
  final String message;

  AppsError(this.message);
}
