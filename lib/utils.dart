import 'dart:math';
import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:pushlock/pushup_state.dart';

double angle(PoseLandmark firstLandmark, PoseLandmark midLandmark,
    PoseLandmark lastLandmark) {
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



PushUpState? isPushUp(double angleElbow, PushUpState current) {
  final umbralElbow = 60.0;
  final umbralElbowExt = 160.0;

  print(
      "First ${current}==${PushUpState.neutral} && ${angleElbow}>${umbralElbowExt} && ${angleElbow}< 180.0");
  print(
      "Second ${current}==${PushUpState.init} && ${angleElbow}<${umbralElbow} && ${angleElbow}< 40.0");

  if (current == PushUpState.neutral &&
      angleElbow > umbralElbowExt &&
      angleElbow < 180.0) {
    return PushUpState.init;
  } else if (current == PushUpState.init &&
      angleElbow < umbralElbow &&
      angleElbow > 40.0) {
    return PushUpState.complete;
  } else {
    return PushUpState.init;
  }
}