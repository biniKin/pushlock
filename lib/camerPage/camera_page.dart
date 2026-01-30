import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/util/calibration_state.dart';
import 'package:pushlock/main.dart';
import 'package:pushlock/util/pushUpDetection.dart';
import 'package:pushlock/util/pushup_state.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.packageName, this.appName = ''});

  final String packageName;
  final String appName;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const int CONFIRM_FRAMES = 2;
  static const int CALIBRATION_FRAMES = 10;
  static const platform = MethodChannel('overlay_channel');

  late int pushupcountforapp;
  final PushupSessionCache pushupSessionCache = PushupSessionCache();

  late CameraController controller;
  late PoseDetector poseDetector;
  final options = PoseDetectorOptions();
  bool _isProcessing = false;
  int pushUpCount = 0;
  PushUpState phase = PushUpState.top;
  List<double> elbowAngles = [];
  List<double> torsoAngles = [];

  // Add these declarations after your existing variables
  double? calibratedTopAngle;
  double? calibratedTorsoAngle;
  double? topThreshold;
  double? bottomThreshold;

  // Reference position for pushup detection
  int downFrames = 0;
  int bottomFrames = 0;
  int goingUpFrames = 0;
  int topFrames = 0;

  Pushupdetection pushupdetection = Pushupdetection();

  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  @override
  void initState() {
    super.initState();
    _initial();
    // cal push ups
    _getPushupCount();
  }

  void _getPushupCount() async {
    pushupcountforapp = await pushupSessionCache.getPushupCount(
      widget.packageName,
    );
    print("number of push ups of this app is: $pushupcountforapp");
  }

  void _initial() async {
    poseDetector = PoseDetector(options: PoseDetectorOptions());

    controller = CameraController(
      cameras[1],
      ResolutionPreset.medium,
      enableAudio: false,
      fps: 10
    );

    controller.initialize().then((_) {
      if (!mounted) return;

      controller.startImageStream((img) async {
        if (_isProcessing) return;
        _isProcessing = true;

        final inputImage = pushupdetection.inputImageFromCameraImage(
          img,
          pushupdetection.getImageRotation(controller),
        );
        final poses = await poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          if (mode == DetectorMode.calibrating) {
            handleCalibration(poses.first);
            _isProcessing = false;
            return;
          }
          detectPushUp(poses.first);
        }

        _isProcessing = false;
      });

      setState(() {});
    });
  }

  Future<void> _unlockApp() async {
    try {
      await platform.invokeMethod('unlock', {
        'packageName': widget.packageName,
      });
    } catch (e) {
      print('Error unlocking app: $e');
    }
  }

  Future<void> _handleUnlock() async {
    // Stop camera
    await controller.stopImageStream();

    // Show success dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🎉 Great Job!'),
        content: Text(
          'You completed $pushUpCount push-ups!\n\n${widget.appName} is now unlocked.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Unlock the app
              await _unlockApp();

              // Close dialog
              if (mounted) Navigator.of(context).pop();

              // Close camera page
              if (mounted) Navigator.of(context).pop();
            },
            child: Text('Continue'),
          ),
        ],
      ),
    );
  }

  void detectPushUp(Pose pose) {
    if (!pushupdetection.bothArmsVisible(pose)) return;

    final angle = pushupdetection.getCombinedElbowAngle(pose);
    if (angle == null || calibratedTopAngle == null) return;
    print(angle);

    switch (phase) {
      case PushUpState.top:
        if (angle < topThreshold!) {
          // Use calibrated threshold
          downFrames++;
          if (downFrames >= CONFIRM_FRAMES) {
            phase = PushUpState.down;
            downFrames = 0;
            debugPrint("⬇️ Confirmed going DOWN");
          }
        } else {
          downFrames = 0;
        }
        break;

      case PushUpState.down:
        if (angle < bottomThreshold!) {
          // Use calibrated threshold
          bottomFrames++;
          if (bottomFrames >= CONFIRM_FRAMES) {
            phase = PushUpState.bottom;
            bottomFrames = 0;
            debugPrint("🔽 Confirmed BOTTOM");
          }
        } else {
          bottomFrames = 0;
        }
        break;

      case PushUpState.bottom:
        if (angle > bottomThreshold! + 30) {
          // Small buffer above bottom
          goingUpFrames++;
          if (goingUpFrames >= CONFIRM_FRAMES) {
            phase = PushUpState.up;
            goingUpFrames = 0;
            debugPrint("⬆️ Confirmed going UP");
          }
        } else {
          goingUpFrames = 0;
        }
        break;

      case PushUpState.up:
        if (angle > topThreshold! - 20) {
          // Small buffer below top
          topFrames++;
          if (topFrames >= CONFIRM_FRAMES) {
            phase = PushUpState.top;
            topFrames = 0;
            pushUpCount++;

            debugPrint("✅ PUSH-UP COUNTED: $pushUpCount");
            setState(() {});

            // Check if pushup count matches required count
            if (pushUpCount >= pushupcountforapp) {
              _handleUnlock();
            }
          }
        } else {
          topFrames = 0;
        }
        break;
    }
  }

  DetectorMode mode = DetectorMode.calibrating;

  void handleCalibration(Pose pose) {
    if (!pushupdetection.bothArmsVisible(pose)) return;
    // if (!pushupdetection.isBodyHorizontal(pose)) return;

    final elbowAngle = pushupdetection.getCombinedElbowAngle(pose);
    if (elbowAngle == null) return;

    final torsoAngle = pushupdetection.calculateTorsoAngle(pose);

    elbowAngles.add(elbowAngle);
    torsoAngles.add(torsoAngle);

    debugPrint("📏 Calibrating... ${elbowAngles.length}/$CALIBRATION_FRAMES");

    if (elbowAngles.length >= CALIBRATION_FRAMES) {
      calibratedTopAngle = _average(elbowAngles);
      calibratedTorsoAngle = _average(torsoAngles);

      // Dynamic thresholds
      topThreshold = calibratedTopAngle! - 15;
      bottomThreshold = calibratedTopAngle! - 60;

      mode = DetectorMode.active;

      debugPrint("✅ Calibration complete");
      debugPrint("Top angle: $calibratedTopAngle");
      debugPrint("Bottom threshold: $bottomThreshold");

      elbowAngles.clear();
      torsoAngles.clear();
    }
  }

  @override
  void dispose() {
    controller.stopImageStream();
    controller.dispose();
    poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ───── Camera Preview ─────
          Positioned.fill(child: CameraPreview(controller)),

          // ───── Dark gradient overlay (cinematic feel) ─────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ),

          // ───── Top HUD ─────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Counter
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "PUSH-UPS",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mode == DetectorMode.active
                                    ? "$pushUpCount"
                                    : "--",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Calibration status
                  if (mode == DetectorMode.calibrating)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Getting ready… ${elbowAngles.length}/$CALIBRATION_FRAMES\nHold your push-up position",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
