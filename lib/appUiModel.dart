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


  Map<String, dynamic> toJson() => {
    'packageName' : packageName,
    'appName':appName,
    'dailyUsageSeconds':dailyUsageSeconds,
    'isLocked':isLocked,
    'timeoutSeconds':timeoutSeconds,
    'icon':icon,
    'versionName':versionName
  };

  factory Appuimodel.fromJson(Map<String, dynamic> json){
    return Appuimodel(
      packageName: json["packageName"], 
      appName: json["appName"], 
      dailyUsageSeconds: json["dailyUsageSeconds"], 
      isLocked: json["isLocked"], 
      versionName: json["versionName"],
    );
  }
}