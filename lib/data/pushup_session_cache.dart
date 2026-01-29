import 'package:hive_flutter/hive_flutter.dart';
import 'package:pushlock/data/pushup_session_model.dart';

class PushupSessionCache {
  static const String _boxName = "pushup_sessions";
  // save to push up session
  Future savePushUp({required String packageName, required int pushupCount})async{
    // open hive box
    final box = await Hive.openBox(_boxName);

    // save data to the box
    box.put(
      packageName, 
      PushupSessionModel(packageName: packageName, pushupCount: pushupCount).toJson()
    );
  }

  // get pushup count for app
  Future<int> getPushupCount(String packageName) async {
    final box = await Hive.openBox(_boxName);

    final raw = box.get(packageName);
    if (raw == null) return 0;

    final session = PushupSessionModel.fromJson(
      Map<String, dynamic>.from(raw),
    );

    return session.pushupCount;
  }

  /// Clear push-up session after unlock
  Future<void> clearPushupSession(String packageName) async {
    final box = await Hive.openBox(_boxName);
    await box.delete(packageName);
  }

  
}