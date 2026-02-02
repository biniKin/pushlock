import 'dart:typed_data';

import 'package:installed_apps/app_category.dart';

class Appuimodel {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final int dailyUsageSeconds;
  final bool isLocked;
  final int? timeoutSeconds;
  final String versionName;
  final AppCategory appCategory;

  Appuimodel({
    required this.packageName,
    required this.appName,
    required this.dailyUsageSeconds,
    required this.isLocked,
    this.timeoutSeconds,
    this.icon,
    required this.versionName,
    required this.appCategory
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'dailyUsageSeconds': dailyUsageSeconds,
    'isLocked': isLocked,
    'timeoutSeconds': timeoutSeconds,
    'icon': icon?.toList(), // Convert Uint8List to List for Hive
    'versionName': versionName,
    'appCategory':appCategory
  };

  factory Appuimodel.fromJson(Map<String, dynamic> json) {
    // Handle icon - convert List<dynamic> back to Uint8List
    Uint8List? icon;
    if (json["icon"] != null) {
      final iconData = json["icon"];
      if (iconData is List) {
        icon = Uint8List.fromList(iconData.cast<int>());
      } else if (iconData is Uint8List) {
        icon = iconData;
      }
    }

    return Appuimodel(
      packageName: json["packageName"],
      appName: json["appName"],
      dailyUsageSeconds: json["dailyUsageSeconds"],
      isLocked: json["isLocked"],
      versionName: json["versionName"],
      icon: icon,
      timeoutSeconds: json["timeoutSeconds"],
      appCategory: json['appCategory']
    );
  }
  Appuimodel copyWith({
    bool? isLocked,
    int? timeoutSeconds,
  }) {
    return Appuimodel(
      packageName: packageName,
      appName: appName,
      icon: icon,
      dailyUsageSeconds: dailyUsageSeconds,
      isLocked: isLocked ?? this.isLocked,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      versionName: versionName,
      appCategory: appCategory
    );
  }

}
