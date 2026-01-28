abstract class HomepageEvent {}

/// Triggered when home page opens
class LoadHomepageData extends HomepageEvent {}

/// Optional: pull-to-refresh
class RefreshHomepageData extends HomepageEvent {}
