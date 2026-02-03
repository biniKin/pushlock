import 'package:installed_apps/app_category.dart';
import 'package:pushlock/model/locked_app.dart';

abstract class AppsEvent {}

/// Called when page opens
class LoadApps extends AppsEvent {}

/// User pulls to refresh / presses refresh button
class RefreshApps extends AppsEvent {}

/// User changes category tab
class CategoryChanged extends AppsEvent {
  final String? appCategory; // null means "All"

  CategoryChanged({this.appCategory});
}

class LockApp extends AppsEvent{
  final LockedApp app;
  final int pushupCount;
  final String selectedCategory;

  LockApp({required this.app, required this.pushupCount, required this.selectedCategory});
}

class UnlockApp extends AppsEvent{
  final String packageName;
  final String selectedCategory;

  UnlockApp({required this.packageName, required this.selectedCategory});
}