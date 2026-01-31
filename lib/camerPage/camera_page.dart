import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/data/pushup_session_cache.dart';
import 'package:pushlock/service/local_pushup_count_service.dart';
import 'package:pushlock/util/calibration_state.dart';
import 'package:pushlock/main.dart';
import 'package:pushlock/util/pushUpDetection.dart';
import 'package:pushlock/util/pushup_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, required this.packageName, this.appName = ''});

  final String packageName;
  final String appName;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const int confirmFrames = 3;
  static const int calibrationFrames = 15;
  static const platform = MethodChannel('overlay_channel');

  late int pushupcountforapp;
  final PushupSessionCache pushupSessionCache = PushupSessionCache();
  


  late CameraController controller;
  late PoseDetector poseDetector;
  bool _isProcessing = false;
  int pushUpCount = 0;

  // Hybrid detection variables
  PushUpState phase = PushUpState.up;

  // Position tracking (normalized 0.0-1.0)
  List<double> shoulderYHistory = [];
  double? baselineShoulderY; // Reference position when in UP state
  double? lowestShoulderY; // Lowest point reached

  // Angle tracking
  List<double> elbowAngleHistory = [];
  double? baselineElbowAngle; // Elbow angle when in UP state

  // Body size reference for normalization
  double? bodySizeReference;

  // Frame counters
  int downConfirmFrames = 0;
  int upConfirmFrames = 0;

  // Calibration
  DetectorMode mode = DetectorMode.calibrating;
  List<double> calibrationShoulderY = [];
  List<double> calibrationElbowAngles = [];

  // Thresholds (will be set during calibration)
  double positionThreshold = 0.08; // 8% of frame height
  double angleThreshold = 30.0; // 30 degrees

  Pushupdetection pushupdetection = Pushupdetection();
  double frameHeight = 1.0;

  double _average(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _movingAverage(List<double> history, double newValue, int maxSize) {
    history.add(newValue);
    if (history.length > maxSize) {
      history.removeAt(0);
    }
    return _average(history);
  }

  @override
  void initState() {
    super.initState();
    _initial();
    _getPushupCount();
  }

  void _getPushupCount() async {
    pushupcountforapp = await pushupSessionCache.getPushupCount(
      widget.packageName,
    );
    debugPrint("Required push-ups: $pushupcountforapp");
  }

  void _initial() async {
    poseDetector = PoseDetector(options: PoseDetectorOptions());

    controller = CameraController(
      cameras[1],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    if (!mounted) return;

    // Get frame dimensions
    frameHeight = controller.value.previewSize?.height ?? 1.0;

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
        } else {
          detectPushUpHybrid(poses.first);
        }
      }

      _isProcessing = false;
    });

    setState(() {});
  }

  Future<void> _unlockApp() async {
    try {
      await platform.invokeMethod('unlock', {
        'packageName': widget.packageName,
      });
    } catch (e) {
      debugPrint('Error unlocking app: $e');
    }
  }

  Future<void> _handleUnlock() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final LocalPushupCountService localPushupCountService = LocalPushupCountService(sharedPreferences: sharedPreferences);

    await controller.stopImageStream();
    await localPushupCountService.savePushupLocally(pushUpCount);


    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Great Job!'),
        content: Text(
          'You completed $pushUpCount push-ups!\n\n${widget.appName} is now unlocked.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _unlockApp();
              if (mounted) Navigator.of(context).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void handleCalibration(Pose pose) {
    // Check if both arms are visible
    if (!pushupdetection.bothArmsVisible(pose)) return;

    // Get shoulder position
    final shoulderY = pushupdetection.getShoulderY(pose, frameHeight);
    if (shoulderY == null) return;

    // Get elbow angle
    final elbowAngle = pushupdetection.getCombinedElbowAngle(pose);
    if (elbowAngle == null) return;

    // Get body size reference
    final bodySize = pushupdetection.getBodySizeReference(pose);
    if (bodySize == null) return;

    calibrationShoulderY.add(shoulderY);
    calibrationElbowAngles.add(elbowAngle);

    debugPrint(
      "📏 Calibrating... ${calibrationShoulderY.length}/$calibrationFrames",
    );

    if (calibrationShoulderY.length >= calibrationFrames) {
      // Set baseline values (user should be in UP position)
      baselineShoulderY = _average(calibrationShoulderY);
      baselineElbowAngle = _average(calibrationElbowAngles);
      bodySizeReference = bodySize;

      // Calculate adaptive thresholds based on body size
      // Larger body = larger displacement expected
      positionThreshold = 0.08; // 8% of frame height
      angleThreshold = 30.0; // 30 degrees minimum bend

      mode = DetectorMode.active;
      phase = PushUpState.up;

      debugPrint("✅ Calibration complete");
      debugPrint("Baseline shoulder Y: $baselineShoulderY");
      debugPrint("Baseline elbow angle: $baselineElbowAngle");
      debugPrint("Position threshold: $positionThreshold");
      debugPrint("Angle threshold: $angleThreshold");

      calibrationShoulderY.clear();
      calibrationElbowAngles.clear();
    }
  }

  void detectPushUpHybrid(Pose pose) {
    // Check if both arms are visible
    if (!pushupdetection.bothArmsVisible(pose)) {
      debugPrint("⚠️ Arms not visible");
      return;
    }

    // Get current shoulder position (normalized)
    final currentShoulderY = pushupdetection.getShoulderY(pose, frameHeight);
    if (currentShoulderY == null) {
      debugPrint("⚠️ Shoulder position unavailable");
      return;
    }

    // Get current elbow angle
    final currentElbowAngle = pushupdetection.getCombinedElbowAngle(pose);
    if (currentElbowAngle == null) {
      debugPrint("⚠️ Elbow angle unavailable");
      return;
    }

    // Apply moving average for smoothing
    final smoothedShoulderY = _movingAverage(
      shoulderYHistory,
      currentShoulderY,
      5,
    );
    final smoothedElbowAngle = _movingAverage(
      elbowAngleHistory,
      currentElbowAngle,
      5,
    );

    // Calculate displacements
    final positionDisplacement =
        smoothedShoulderY - (baselineShoulderY ?? smoothedShoulderY);
    final angleChange =
        (baselineElbowAngle ?? smoothedElbowAngle) - smoothedElbowAngle;

    debugPrint(
      "Position: $smoothedShoulderY, Displacement: ${positionDisplacement.toStringAsFixed(3)}, Angle: ${smoothedElbowAngle.toStringAsFixed(1)}°, Change: ${angleChange.toStringAsFixed(1)}°",
    );

    switch (phase) {
      case PushUpState.up:
        // Detect going DOWN
        // Position: Shoulder moved down (Y increased)
        // Angle: Elbow bent (angle decreased)
        if (positionDisplacement > positionThreshold &&
            angleChange > angleThreshold) {
          downConfirmFrames++;
          if (downConfirmFrames >= confirmFrames) {
            phase = PushUpState.down;
            lowestShoulderY = smoothedShoulderY;
            downConfirmFrames = 0;
            debugPrint(
              "⬇️ Confirmed DOWN - Position: ${positionDisplacement.toStringAsFixed(3)}, Angle: ${angleChange.toStringAsFixed(1)}°",
            );
          }
        } else {
          downConfirmFrames = 0;
        }
        break;

      case PushUpState.down:
        // Track lowest point
        if (smoothedShoulderY > (lowestShoulderY ?? 0)) {
          lowestShoulderY = smoothedShoulderY;
        }

        // Detect going UP
        // Position: Shoulder moved up from lowest point (Y decreased)
        // Angle: Elbow extended (angle increased back toward baseline)
        final upDisplacement =
            (lowestShoulderY ?? smoothedShoulderY) - smoothedShoulderY;
        final angleRecovery =
            smoothedElbowAngle - (baselineElbowAngle! - angleThreshold);

        if (upDisplacement > positionThreshold * 0.7 &&
            angleRecovery > angleThreshold * 0.5) {
          upConfirmFrames++;
          if (upConfirmFrames >= confirmFrames) {
            // PUSHUP COUNTED!
            phase = PushUpState.up;
            pushUpCount++;
            upConfirmFrames = 0;

            // Reset baseline to current position (adaptive)
            baselineShoulderY = smoothedShoulderY;
            baselineElbowAngle = smoothedElbowAngle;

            debugPrint("✅ PUSH-UP #$pushUpCount COUNTED!");
            setState(() {});

            // Check if goal reached
            if (pushUpCount >= pushupcountforapp) {
              _handleUnlock();
            }
          }
        } else {
          upConfirmFrames = 0;
        }
        break;
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
          // Camera Preview
          Positioned.fill(child: CameraPreview(controller)),

          // Dark gradient overlay
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

          // Top HUD
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
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
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
                                    ? "$pushUpCount / $pushupcountforapp"
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
                        color: Colors.blue.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Getting ready… ${calibrationShoulderY.length}/$calibrationFrames\nHold arms extended (top position)",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // State indicator
                  if (mode == DetectorMode.active)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: phase == PushUpState.up
                            ? Colors.green.withValues(alpha: 0.7)
                            : Colors.orange.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        phase == PushUpState.up ? "UP ⬆️" : "DOWN ⬇️",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
