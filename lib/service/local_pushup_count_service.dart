import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LocalPushupCountService {
  final SharedPreferences sharedPreferences;
  static const String _key = "total_pushups";

  final StreamController<int> _pushupController = StreamController<int>.broadcast();

  LocalPushupCountService({required this.sharedPreferences}) {
    // Emit initial value synchronously so listeners get current count immediately
    _pushupController.add(getPushupCountLocally());
  }

  Stream<int> get pushupCountStream => _pushupController.stream;

  // save push up count
  Future<void> savePushupLocally(int pushupcount) async {
    await sharedPreferences.setInt(_key, pushupcount);
    _pushupController.add(pushupcount);
  }

  // increment total pushups by delta
  Future<void> incrementPushups(int delta) async {
    final current = getPushupCountLocally();
    final updated = current + delta;
    await savePushupLocally(updated);
    _pushupController.add(updated);
  }

  // get push up count
  int getPushupCountLocally(){
    final pushups = sharedPreferences.getInt(_key);

    if(pushups != null) {
      return pushups;
    } else{
      return 0;
    }
    
  }

  // delete push up counts
  Future<void> deletePushupCountLocally()async{
    await sharedPreferences.remove(_key);
  }

  void dispose() {
    _pushupController.close();
  }

}