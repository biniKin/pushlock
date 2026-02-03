import 'package:shared_preferences/shared_preferences.dart';

class IntroPageFlag {
  final SharedPreferences sharedPreferences;

  IntroPageFlag({required this.sharedPreferences});
  // create flag
  Future createIntroPageFlag()async{
    try{
      await sharedPreferences.setBool("intro_visible", true);
    }catch(e){
      print("error: $e");
    }
    
  }

  // get flag
  Future<bool> getIntroPageFlag() async {
    final res = sharedPreferences.getBool("intro_visible");

    if(res == null){
      return false;
    } else{
      return res;
    }
  }
}