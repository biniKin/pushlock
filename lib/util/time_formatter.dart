class TimeFormatter {
  /// Convert seconds to human-readable format
  /// Examples:
  /// - 90 seconds → "1 min"
  /// - 3600 seconds → "1 hour"
  /// - 5400 seconds → "1 hour 30 min"
  /// - 45 seconds → "45 sec"
  static String formatSeconds(int seconds) {
    if (seconds < 60) {
      return "$seconds sec";
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return "$hours hour${hours > 1 ? 's' : ''} $minutes min";
    } else if (hours > 0) {
      return "$hours hour${hours > 1 ? 's' : ''}";
    } else {
      return "$minutes min";
    }
  }

  /// Convert seconds to short format (for charts)
  /// Examples:
  /// - 90 seconds → "1m"
  /// - 3600 seconds → "1h"
  /// - 5400 seconds → "1h 30m"
  static String formatSecondsShort(int seconds) {
    if (seconds < 60) {
      return "${seconds}s";
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0 && minutes > 0) {
      return "${hours}h ${minutes}m";
    } else if (hours > 0) {
      return "${hours}h";
    } else {
      return "${minutes}m";
    }
  }
}
