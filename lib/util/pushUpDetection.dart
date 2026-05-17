import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/main.dart';

class Pushupdetection {
  static const double CRITICAL_CONFIDENCE = 0.8;
  static const double NORMAL_CONFIDENCE = 0.7;

  // ────────────────────────────────────────────────
  // Coordinate transformation helpers
  // ────────────────────────────────────────────────

  double translateX(
    double x,
    InputImageRotation rotation,
    Size canvasSize,
    Size imageSize,
    CameraLensDirection direction,
  ) {
    double translated = x;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
        translated = x * canvasSize.width / imageSize.width;
        break;
      case InputImageRotation.rotation90deg:
        translated = x * canvasSize.width / imageSize.height;
        break;
      case InputImageRotation.rotation180deg:
        translated =
            canvasSize.width - (x * canvasSize.width / imageSize.width);
        break;
      case InputImageRotation.rotation270deg:
        translated =
            canvasSize.width - (x * canvasSize.width / imageSize.height);
        break;
    }

    // Mirror for front camera (user's right appears left in preview)
    if (direction == CameraLensDirection.front) {
      translated = canvasSize.width - translated;
    }

    return translated;
  }

  double translateY(
    double y,
    InputImageRotation rotation,
    Size canvasSize,
    Size imageSize,
    CameraLensDirection direction,
  ) {
    double translated = y;

    switch (rotation) {
      case InputImageRotation.rotation0deg:
        translated = y * canvasSize.height / imageSize.height;
        break;
      case InputImageRotation.rotation90deg:
        translated =
            canvasSize.height - (y * canvasSize.height / imageSize.width);
        break;
      case InputImageRotation.rotation180deg:
        translated =
            canvasSize.height - (y * canvasSize.height / imageSize.height);
        break;
      case InputImageRotation.rotation270deg:
        translated = y * canvasSize.height / imageSize.width;
        break;
    }

    return translated;
  }

  PoseLandmark? getTransformedLandmark(
    Pose pose,
    PoseLandmarkType type,
    InputImageRotation rotation,
    Size canvasSize,
    Size imageSize,
    CameraLensDirection direction,
  ) {
    final lm = pose.landmarks[type];
    if (lm == null) return null;

    final tx = translateX(lm.x, rotation, canvasSize, imageSize, direction);
    final ty = translateY(lm.y, rotation, canvasSize, imageSize, direction);

    return PoseLandmark(
      type: lm.type,
      likelihood: lm.likelihood,
      x: tx,
      y: ty,
      z: lm.z,
    );
  }

  // Updated – uses transformed coordinates
  bool isBodyHorizontal(
    Pose pose,
    InputImageRotation rotation,
    Size canvasSize,
    Size imageSize,
    CameraLensDirection direction, {
    double tolerance = 25.0,
  }) {
    final shoulder = getTransformedLandmark(
      pose,
      PoseLandmarkType.rightShoulder,
      rotation,
      canvasSize,
      imageSize,
      direction,
    );
    final hip = getTransformedLandmark(
      pose,
      PoseLandmarkType.rightHip,
      rotation,
      canvasSize,
      imageSize,
      direction,
    );

    if (shoulder == null || hip == null) return false;

    final dx = hip.x - shoulder.x;
    final dy = hip.y - shoulder.y;

    final angle = (atan2(dy, dx) * 180 / pi).abs();
    return angle < tolerance || angle > (180 - tolerance);
  }

  // Updated – relative threshold
  bool wristsUnderShoulders(
    Pose pose,
    InputImageRotation rotation,
    Size canvasSize,
    Size imageSize,
    CameraLensDirection direction,
    double? bodySizeRef,
  ) {
    final shoulder = getTransformedLandmark(
      pose,
      PoseLandmarkType.rightShoulder,
      rotation,
      canvasSize,
      imageSize,
      direction,
    );
    final wrist = getTransformedLandmark(
      pose,
      PoseLandmarkType.rightWrist,
      rotation,
      canvasSize,
      imageSize,
      direction,
    );

    if (shoulder == null || wrist == null) return false;

    final dx = (shoulder.x - wrist.x).abs();

    final threshold = bodySizeRef != null
        ? bodySizeRef * 0.18
        : canvasSize.width * 0.10;

    return dx < threshold;
  }

  // Get average shoulder Y position (normalized to frame height)
  double? getShoulderY(Pose pose, double frameHeight) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

    if (leftShoulder == null || rightShoulder == null) return null;

    if (!isLandmarkReliable(leftShoulder, min: NORMAL_CONFIDENCE) ||
        !isLandmarkReliable(rightShoulder, min: NORMAL_CONFIDENCE)) {
      return null;
    }

    // Average Y position, normalized to frame height (0.0 to 1.0)
    final avgY = (leftShoulder.y + rightShoulder.y) / 2;
    return avgY / frameHeight;
  }

  // Get body size reference (shoulder to hip distance)
  double? getBodySizeReference(Pose pose) {
    final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final hip = pose.landmarks[PoseLandmarkType.rightHip];

    if (shoulder == null || hip == null) return null;

    if (!isLandmarkReliable(shoulder, min: NORMAL_CONFIDENCE) ||
        !isLandmarkReliable(hip, min: NORMAL_CONFIDENCE)) {
      return null;
    }

    final dx = hip.x - shoulder.x;
    final dy = hip.y - shoulder.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  // Get hip Y position as fallback
  double? getHipY(Pose pose, double frameHeight) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];

    if (leftHip == null || rightHip == null) return null;

    if (!isLandmarkReliable(leftHip, min: NORMAL_CONFIDENCE) ||
        !isLandmarkReliable(rightHip, min: NORMAL_CONFIDENCE)) {
      return null;
    }

    final avgY = (leftHip.y + rightHip.y) / 2;
    return avgY / frameHeight;
  }

  double angle(
    PoseLandmark firstLandmark,
    PoseLandmark midLandmark,
    PoseLandmark lastLandmark,
  ) {
    double radians =
        atan2(lastLandmark.y - midLandmark.y, lastLandmark.x - midLandmark.x) -
        atan2(firstLandmark.y - midLandmark.y, firstLandmark.x - midLandmark.x);
    double degrees = radians * 180.0 / math.pi;
    degrees = degrees.abs(); // Angle should never be negative
    if (degrees > 180.0) {
      degrees =
          360.0 - degrees; // Always get the acute representation of the angle
    }
    return degrees;
  }

  double calculateJointAngle(
    PoseLandmark start,
    PoseLandmark joint,
    PoseLandmark end,
  ) {
    final radians =
        atan2(end.y - joint.y, end.x - joint.x) -
        atan2(start.y - joint.y, start.x - joint.x);

    var degrees = radians.abs() * 180.0 / math.pi;
    if (degrees > 180) degrees = 360 - degrees;
    return degrees;
  }

  bool isLandmarkReliable(PoseLandmark lm, {double min = 0.7}) {
    return lm.likelihood >= min;
  }

  bool hasReliableArm(Pose pose, bool isRight) {
    final shoulder =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightShoulder
            : PoseLandmarkType.leftShoulder];
    final elbow =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightElbow
            : PoseLandmarkType.leftElbow];
    final wrist =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightWrist
            : PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return false;

    return isLandmarkReliable(shoulder, min: NORMAL_CONFIDENCE) &&
        isLandmarkReliable(elbow, min: CRITICAL_CONFIDENCE) &&
        isLandmarkReliable(wrist, min: NORMAL_CONFIDENCE);
  }

  double? getElbowAngle(Pose pose, bool isRight) {
    final shoulder =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightShoulder
            : PoseLandmarkType.leftShoulder];
    final elbow =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightElbow
            : PoseLandmarkType.leftElbow];
    final wrist =
        pose.landmarks[isRight
            ? PoseLandmarkType.rightWrist
            : PoseLandmarkType.leftWrist];

    if (shoulder == null || elbow == null || wrist == null) return null;

    if (!isLandmarkReliable(elbow, min: CRITICAL_CONFIDENCE)) return null;

    return calculateJointAngle(shoulder, elbow, wrist);
  }

  double? getCombinedElbowAngle(Pose pose) {
    final rightAngle = getElbowAngle(pose, true);
    final leftAngle = getElbowAngle(pose, false);

    if (rightAngle != null && leftAngle != null) {
      // Could weight by confidence if needed
      return (rightAngle + leftAngle) / 2; // BEST CASE
    }

    return rightAngle ?? leftAngle; // fallback
  }

  bool bothArmsVisible(Pose pose) {
    return hasReliableArm(pose, true) && hasReliableArm(pose, false);
  }

  // Check if user is facing camera (front view, not profile)
  bool isFacingCamera(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null ||
        nose == null) {
      return false;
    }

    // Check confidence
    if (leftShoulder.likelihood < NORMAL_CONFIDENCE ||
        rightShoulder.likelihood < NORMAL_CONFIDENCE ||
        nose.likelihood < NORMAL_CONFIDENCE) {
      return false;
    }

    // 1. Check shoulder width (both shoulders should be visible and separated)
    final shoulderWidth = (leftShoulder.x - rightShoulder.x).abs();
    final shoulderMidX = (leftShoulder.x + rightShoulder.x) / 2;

    // Shoulders should be reasonably wide apart (not profile view)
    // In profile view, shoulders overlap or are very close
    final bodySize = getBodySizeReference(pose) ?? 100;
    if (shoulderWidth < bodySize * 0.3) {
      return false; // Too narrow, likely profile view
    }

    // 2. Check nose position relative to shoulders
    // Nose should be roughly centered between shoulders (front view)
    // In profile view, nose is off to one side
    final noseOffset = (nose.x - shoulderMidX).abs();
    if (noseOffset > shoulderWidth * 0.4) {
      return false; // Nose too far from center, likely profile
    }

    // 3. Check hip width (both hips should be visible)
    final hipWidth = (leftHip.x - rightHip.x).abs();
    if (hipWidth < bodySize * 0.25) {
      return false; // Hips too narrow, likely profile
    }

    return true;
  }

  //   bool isBodyHorizontal(
  //   Pose pose,
  //   InputImageRotation rotation,
  //   Size canvas,
  //   Size image,
  //   CameraLensDirection dir,
  //   {double tolerance = 25}) {
  //   final rShoulder = getTransformedLandmark(pose, PoseLandmarkType.rightShoulder, rotation, canvas, image, dir);
  //   final rHip = getTransformedLandmark(pose, PoseLandmarkType.rightHip, rotation, canvas, image, dir);

  //   if (rShoulder == null || rHip == null) return false;

  //   final dx = rHip.x - rShoulder.x;
  //   final dy = rHip.y - rShoulder.y;

  //   final angle = (math.atan2(dy, dx) * 180 / math.pi).abs();
  //   return angle < tolerance || angle > (180 - tolerance);
  // }

  // bool wristsUnderShoulders(
  //   Pose pose,
  //   InputImageRotation rot,
  //   Size canvas,
  //   Size image,
  //   CameraLensDirection dir,
  //   double? bodySizeRef,
  // ) {
  //   final rShoulder = getTransformedLandmark(pose, PoseLandmarkType.rightShoulder, rot, canvas, image, dir);
  //   final rWrist = getTransformedLandmark(pose, PoseLandmarkType.rightWrist, rot, canvas, image, dir);

  //   if (rShoulder == null || rWrist == null) return false;

  //   final dx = (rShoulder.x - rWrist.x).abs();

  //   // Relative threshold – much better than 40 pixels
  //   final threshold = bodySizeRef != null ? bodySizeRef * 0.15 : canvas.width * 0.08;

  //   return dx < threshold;
  // }

  InputImage inputImageFromCameraImage(
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

  InputImageRotation getImageRotation(controller) {
    final camera =
        cameras[controller.description.lensDirection ==
                CameraLensDirection.front
            ? 1
            : 0];

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
}
