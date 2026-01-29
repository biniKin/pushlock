class LockedApp {
  final String packageName;
  final String appName;
  final int timeoutSeconds;
  final bool isStrict;


  LockedApp({
    required this.packageName,
    required this.appName,
    required this.isStrict,
    required this.timeoutSeconds,

  });

  // form json
  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: json['packageName'],
      appName: json["appName"],
      isStrict: json["isStrict"],
      timeoutSeconds: json["timeoutSecond"] ?? json["timeoutSeconds"],

    );
  }

  // Parse list of JSON maps to list of LockedApp objects
  static List<LockedApp> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => LockedApp.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
