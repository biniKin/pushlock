abstract class AppsEvent {}

/// Called when page opens
class LoadApps extends AppsEvent {}

/// User pulls to refresh / presses refresh button
class RefreshApps extends AppsEvent {}
