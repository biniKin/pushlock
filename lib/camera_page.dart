import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/main.dart';
import 'package:pushlock/pushup_state.dart';
import 'package:pushlock/utils.dart';


const int CONFIRM_FRAMES = 4;


class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  
  late CameraController controller;
  late PoseDetector poseDetector;
  final options = PoseDetectorOptions();
  bool _isProcessing = false;
  int pushUpCount = 0;
  PushUpState phase = PushUpState.top;

  // Reference position for pushup detection
  int downFrames = 0;
  int bottomFrames = 0;
  int upFrames = 0;
  


  InputImageRotation _getImageRotation() {
    final camera = cameras[controller.description.lensDirection == CameraLensDirection.front ? 1 : 0];
    
    switch (camera.sensorOrientation) {
        case 90:
          return InputImageRotation.rotation90deg;
        case 180:
          return InputImageRotation.rotation180deg;
        case 270:
          return InputImageRotation.rotation270deg;
        default:
          return InputImageRotation.rotation0deg;
      }
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

        final inputImage = inputImageFromCameraImage(img, _getImageRotation());
        final poses = await poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) detectPushUp(poses.first);

        _isProcessing = false;
      });

      setState(() {});
    });
  }

  void detectPushUp(Pose pose) {
  
  if (!isBodyHorizontal(pose)) return;
  if (!bothArmsVisible(pose)) return;

  final angle = getCombinedElbowAngle(pose);
  if (angle == null) return;

  switch (phase) {

    case PushUpState.top:
      if (angle < 140) {
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
      if (angle < 90) {
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
      if (angle > 120) {
        upFrames++;
        if (upFrames >= CONFIRM_FRAMES) {
          phase = PushUpState.up;
          upFrames = 0;
          debugPrint("⬆️ Confirmed going UP");
        }
      } else {
        upFrames = 0;
      }
      break;

    case PushUpState.up:
      if (angle > 160) {
        upFrames++;
        if (upFrames >= CONFIRM_FRAMES) {
          phase = PushUpState.top;
          upFrames = 0;
          pushUpCount++;
          debugPrint("✅ PUSH-UP COUNTED: $pushUpCount");
        }
      } else {
        upFrames = 0;
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
    if (!controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(controller),
          // Pushup counter overlay
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Push-ups: $pushUpCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // State indicator (for debugging)
          // Positioned(
          //   bottom: 50,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: Container(
          //       padding: const EdgeInsets.symmetric(
          //         horizontal: 20,
          //         vertical: 8,
          //       ),
          //       decoration: BoxDecoration(
          //         color: _isInDownPosition
          //             ? Colors.orange.withValues(alpha: 0.7)
          //             : Colors.green.withValues(alpha: 0.7),
          //         borderRadius: BorderRadius.circular(15),
          //       ),
          //       child: Text(
          //         _isInDownPosition ? 'DOWN' : 'UP',
          //         style: const TextStyle(
          //           color: Colors.white,
          //           fontSize: 24,
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
