import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';


class CameraStreamPayload {

  Uint8List yuvBytes;
  int imageWidth;
  int imageHeight;
  int rotation;
  InputImage inputImage;
  CameraImage cameraImage;

  CameraStreamPayload({
    required this.inputImage,
    required this.yuvBytes,
    required this.imageWidth,
    required this.imageHeight,
    required this.rotation,
    required this.cameraImage
  });


}