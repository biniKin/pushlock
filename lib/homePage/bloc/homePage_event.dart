import 'package:pushlock/model/locked_app.dart';

abstract class HomepageEvent {}

/// Triggered when home page opens
class LoadHomepageData extends HomepageEvent {}

/// Optional: pull-to-refresh
class RefreshHomepageData extends HomepageEvent {}

class LockAppRequested extends HomepageEvent {
  final LockedApp app;

  LockAppRequested({
    required this.app
  });
}

class UnlockAppRequested extends HomepageEvent {
  final String packageName;

  UnlockAppRequested(this.packageName);
}