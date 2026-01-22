import 'package:flutter/material.dart';
import 'package:pushlock/lock_overlay_app.dart';

@pragma("vm:entry-point")
void overLayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  print("*******************************OVERLAY ISOLATE STARTED");
  runApp(const LockOverlayApp());
}
