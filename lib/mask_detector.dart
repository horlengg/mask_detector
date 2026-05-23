
import 'package:flutter/services.dart';
import 'package:mask_detector/models/mask_detection_result.dart';

import 'mask_detector_platform_interface.dart';

class MaskDetector {
  
  static Future<Map<String, dynamic>> initialize() {
    return MaskDetectorPlatform.instance.initialize();
  }


  static Future<MaskDetectionResult> detect(Uint8List yuvBytes,{
    required double imageWidth,
    required double imageHeight,
    required Rect faceCountour,
    required int bytesPerRow,
    int rotation = 0,
  }) {
    return MaskDetectorPlatform.instance.detectMask(
      yuvBytes,
      imageHeight: imageHeight,
      imageWidth: imageWidth,
      faceCountour: faceCountour,
      rotation: rotation,
      bytesPerRow : bytesPerRow
    );
  }

  static Future<Map<String, dynamic>> destroy() {
    return MaskDetectorPlatform.instance.destroy();
  }

}
