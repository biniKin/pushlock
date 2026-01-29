class Appstatmodel {
  String packageName;
  String appName;
  String dailyUsageTime;
  String date;

  Appstatmodel({
    required this.appName, 
    required this.dailyUsageTime,
    required this.date,
    required this.packageName
  });

  factory Appstatmodel.fromJson(Map<String, dynamic> json){
    return Appstatmodel(
      appName: json['appName'], 
      dailyUsageTime: json["dailyUsageTime"],
      date: json["date"], 
      packageName: json["packageName"],
    );
  }

  static List<Appstatmodel> fromJsonList(List<dynamic> jsonList){
    return jsonList.map((json) => Appstatmodel.fromJson(json)).toList();
  }
}