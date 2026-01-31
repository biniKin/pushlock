import 'package:shared_preferences/shared_preferences.dart';

class LocalPushupCountService {
  final SharedPreferences sharedPreferences;
  static const String _key = "total_pushups";

  LocalPushupCountService({required this.sharedPreferences});
  // save push up count
  Future<void> savePushupLocally(int pushupcount)async{
    await sharedPreferences.setInt(_key, pushupcount);
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

}