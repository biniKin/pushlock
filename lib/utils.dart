import 'dart:math';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/pushup_state.dart';


const double CRITICAL_CONFIDENCE = 0.8;
const double NORMAL_CONFIDENCE = 0.7;


double angle(
  PoseLandmark firstLandmark, 
  PoseLandmark midLandmark,
  PoseLandmark lastLandmark,
  ) {
  double radians = atan2(
          lastLandmark.y - midLandmark.y, lastLandmark.x - midLandmark.x) -
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

bool isBodyHorizontal(Pose pose) {
  final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
  final hip = pose.landmarks[PoseLandmarkType.rightHip];

  if (shoulder == null || hip == null) return false;

  final dx = hip.x - shoulder.x;
  final dy = hip.y - shoulder.y;

  final angle = (atan2(dy, dx) * 180 / pi).abs();

  // Near horizontal (~0° or ~180°)
  return angle < 20 || angle > 160;
}

bool wristsUnderShoulders(Pose pose) {
  final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
  final wrist = pose.landmarks[PoseLandmarkType.rightWrist];

  if (shoulder == null || wrist == null) return false;

  return (shoulder.x - wrist.x).abs() < 40;
}

bool isLandmarkReliable(PoseLandmark lm, {double min = 0.7}) {
  return lm.likelihood >= min;
}



bool hasReliableArm(Pose pose, bool isRight) {
  final shoulder = pose.landmarks[
      isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder];
  final elbow = pose.landmarks[
      isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow];
  final wrist = pose.landmarks[
      isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist];

  if (shoulder == null || elbow == null || wrist == null) return false;

  return isLandmarkReliable(shoulder, min: NORMAL_CONFIDENCE) &&
         isLandmarkReliable(elbow, min: CRITICAL_CONFIDENCE) &&
         isLandmarkReliable(wrist, min: NORMAL_CONFIDENCE);
}


double? getElbowAngle(Pose pose, bool isRight) {
  final shoulder = pose.landmarks[
      isRight ? PoseLandmarkType.rightShoulder : PoseLandmarkType.leftShoulder];
  final elbow = pose.landmarks[
      isRight ? PoseLandmarkType.rightElbow : PoseLandmarkType.leftElbow];
  final wrist = pose.landmarks[
      isRight ? PoseLandmarkType.rightWrist : PoseLandmarkType.leftWrist];

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


double calculateTorsoAngle(Pose pose) {
  final shoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
  final hip = pose.landmarks[PoseLandmarkType.rightHip];

  if (shoulder == null || hip == null) return 90;

  final dx = hip.x - shoulder.x;
  final dy = hip.y - shoulder.y;

  return (atan2(dy, dx) * 180 / pi).abs();
}



// PushUpState? isPushUp(double angleElbow, PushUpState current) {
//   final umbralElbow = 60.0;
//   final umbralElbowExt = 160.0;

//   print(
//       "First ${current}==${PushUpState.neutral} && ${angleElbow}>${umbralElbowExt} && ${angleElbow}< 180.0");
//   print(
//       "Second ${current}==${PushUpState.init} && ${angleElbow}<${umbralElbow} && ${angleElbow}< 40.0");

//   if (current == PushUpState.neutral &&
//       angleElbow > umbralElbowExt &&
//       angleElbow < 180.0) {
//     return PushUpState.init;
//   } else if (current == PushUpState.init &&
//       angleElbow < umbralElbow &&
//       angleElbow > 40.0) {
//     return PushUpState.complete;
//   } else {
//     return PushUpState.init;
//   }
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