import 'package:installed_apps/app_category.dart';

abstract class AppsEvent {}

/// Called when page opens
class LoadApps extends AppsEvent {}

/// User pulls to refresh / presses refresh button
class RefreshApps extends AppsEvent {}

/// User changes category tab
class CategoryChanged extends AppsEvent {
  final AppCategory? appCategory; // null means "All"

  CategoryChanged({this.appCategory});
}
