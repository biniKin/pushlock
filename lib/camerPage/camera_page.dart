import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/util/calibration_state.dart';
import 'package:pushlock/main.dart';
import 'package:pushlock/util/pushUpDetection.dart';
import 'package:pushlock/util/pushup_state.dart';





class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  static const int CONFIRM_FRAMES = 4;
  static const int CALIBRATION_FRAMES = 20;
  
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

  }

  void _initial()async{
    poseDetector = PoseDetector(options: PoseDetectorOptions());

    controller = CameraController(
      cameras[1],
      ResolutionPreset.medium,
      enableAudio: false,
      fps: 10,
    );

    controller.initialize().then((_) {
      if (!mounted) return;

      controller.startImageStream((img) async {
        if (_isProcessing) return;
        _isProcessing = true;

        final inputImage = pushupdetection.inputImageFromCameraImage(img, pushupdetection.getImageRotation(controller));
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

  void detectPushUp(Pose pose) {
    if (!pushupdetection.bothArmsVisible(pose)) return;

    final angle = pushupdetection.getCombinedElbowAngle(pose);
    if (angle == null || calibratedTopAngle == null) return;

    switch (phase) {
      case PushUpState.top:
        if (angle < topThreshold!) {  // Use calibrated threshold
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
        if (angle < bottomThreshold!) {  // Use calibrated threshold
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
        if (angle > bottomThreshold! + 20) {  // Small buffer above bottom
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
        if (angle > topThreshold! - 10) {  // Small buffer below top
          topFrames++;
          if (topFrames >= CONFIRM_FRAMES) {
            phase = PushUpState.top;
            topFrames = 0;
            pushUpCount++;
            debugPrint("✅ PUSH-UP COUNTED: $pushUpCount");
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
    if (!pushupdetection.isBodyHorizontal(pose)) return;

    final elbowAngle = pushupdetection.getCombinedElbowAngle(pose);
    if (elbowAngle == null) return;

    final torsoAngle = pushupdetection.calculateTorsoAngle(pose);

    elbowAngles.add(elbowAngle);
    torsoAngles.add(torsoAngle);

    debugPrint(
      "📏 Calibrating... ${elbowAngles.length}/$CALIBRATION_FRAMES",
    );

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
      body: Stack(
        children: [
          CameraPreview(controller),
          
          // Calibration indicator
          if (mode == DetectorMode.calibrating)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Calibrating... ${elbowAngles.length}/$CALIBRATION_FRAMES\nHold plank position',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),

          // Push-up counter
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: mode == DetectorMode.active 
                    ? Colors.black.withOpacity(0.7) 
                    : Colors.grey.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mode == DetectorMode.active 
                    ? 'Push-ups: $pushUpCount' 
                    : 'Calibrating...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}