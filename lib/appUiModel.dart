import 'dart:typed_data';

class Appuimodel {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int dailyUsageSeconds;
  final bool isLocked;
  final int? timeoutSeconds;
  final String versionName;

  Appuimodel({
    required this.packageName,
    required this.appName,
    required this.dailyUsageSeconds,
    required this.isLocked,
    this.timeoutSeconds,
    this.icon,
    required this.versionName
  });
}