class Appstatmodel {
  String packageName;
  String appName;
  int dailyUsageTime; // Changed from String to int
  String date;

  Appstatmodel({
    required this.appName,
    required this.dailyUsageTime,
    required this.date,
    required this.packageName,
  });

  factory Appstatmodel.fromJson(Map<String, dynamic> json) {
    return Appstatmodel(
      appName: json['appName'],
      dailyUsageTime: json["dailyUsageTime"] is int
          ? json["dailyUsageTime"]
          : int.tryParse(json["dailyUsageTime"].toString()) ?? 0,
      date: json["date"],
      packageName: json["packageName"],
    );
  }

  static List<Appstatmodel> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => 
    Appstatmodel.fromJson(Map<String, dynamic>.from(json))).toList();
  }
}
