


class PushupSessionModel{

  int pushupCount;

  String packageName;

  PushupSessionModel({required this.packageName, required this.pushupCount});


  // tosjson
  Map<String, dynamic> toJson() => {
    'packageName' : packageName,
    'pushupCount': pushupCount
  };

  // from json
  factory PushupSessionModel.fromJson(Map<String, dynamic> json){
    return PushupSessionModel(packageName: json["packageName"], pushupCount: json["pushupCount"]);
  }

}