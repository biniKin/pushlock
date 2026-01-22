import 'package:flutter/services.dart';

class ForegroundService {
  static const _foregroundChannel = EventChannel("foreground_app_stream");

  static Stream<String> get foregroundApps {
    return _foregroundChannel.receiveBroadcastStream().map((event) => event as String);
  }
}