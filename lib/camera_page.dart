import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/main.dart';

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

  // Reference position for pushup detection
  double? _referenceChestY;
  double? _upPositionY;
  double? _downPositionY;

  // Pushup state tracking
  bool _isInDownPosition = false;

  // Rotation for camera image
  final rotation = InputImageRotation.rotation0deg;

  @override
  void initState() {
    super.initState();

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

        final inputImage = _inputImageFromCameraImage(img, rotation);
        final poses = await poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) detectPushUp(poses.first);

        _isProcessing = false;
      });

      setState(() {});
    });
  }

  InputImage _inputImageFromCameraImage(
    CameraImage image,
    InputImageRotation rotation,
  ) {
    final int width = image.width;
    final int height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final nv21 = Uint8List(width * height * 3 ~/ 2);

    // Copy Y plane
    for (int row = 0; row < height; row++) {
      nv21.setRange(
        row * width,
        row * width + width,
        yPlane.bytes,
        row * yPlane.bytesPerRow,
      );
    }

    // Copy interleaved VU (chroma) planes
    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;
    int nv21Offset = width * height;

    for (int row = 0; row < chromaHeight; row++) {
      for (int col = 0; col < chromaWidth; col++) {
        final uIndex = row * uPlane.bytesPerRow + col;
        final vIndex = row * vPlane.bytesPerRow + col;

        nv21[nv21Offset++] = vPlane.bytes[vIndex];
        nv21[nv21Offset++] = uPlane.bytes[uIndex];
      }
    }

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  void detectPushUp(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    // Check if all required landmarks are detected
    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return;
    }

    // Calculate chest Y position (average of shoulders)
    double chestY = (leftShoulder.y + rightShoulder.y) / 2;

    // Calculate hip Y position for better detection
    double hipY = (leftHip.y + rightHip.y) / 2;

    // Calculate torso length for relative thresholds
    double torsoLength = (hipY - chestY).abs();

    // Initialize reference position on first detection (user should start in UP position)
    if (_referenceChestY == null) {
      _referenceChestY = chestY;
      _upPositionY = chestY;
      debugPrint("Reference position set: chest=$chestY, torso=$torsoLength");
      return;
    }

    // Use relative thresholds based on torso length (more robust)
    // User goes DOWN when chest moves down by ~30% of torso length
    // User goes UP when chest returns to within ~15% of reference
    double downThreshold = _referenceChestY! + (torsoLength * 0.3);
    double upThreshold = _referenceChestY! + (torsoLength * 0.15);

    if (!_isInDownPosition && chestY > downThreshold) {
      // User went down
      _isInDownPosition = true;
      _downPositionY = chestY;
      debugPrint("State: DOWN (chest at $chestY, threshold: $downThreshold)");
      setState(() {}); // Update UI
    } else if (_isInDownPosition && chestY < upThreshold) {
      // User came back up - count the pushup!
      _isInDownPosition = false;
      pushUpCount++;
      debugPrint(
        "Push-up #$pushUpCount completed! (chest at $chestY, threshold: $upThreshold)",
      );

      // Update reference to current up position for better tracking
      _referenceChestY = chestY;
      _upPositionY = chestY;
      setState(() {}); // Update UI
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
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _isInDownPosition
                      ? Colors.orange.withValues(alpha: 0.7)
                      : Colors.green.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  _isInDownPosition ? 'DOWN' : 'UP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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
