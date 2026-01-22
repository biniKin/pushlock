import 'package:flutter/material.dart';
import 'package:pushlock/lock_screen.dart';

class LockOverlayApp extends StatelessWidget {
  const LockOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LockScreen(),
    );
  }
}