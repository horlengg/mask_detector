import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mask_detector/models/mask_detection_result.dart';
import 'package:mask_detector/models/mask_detector_exception.dart';

import 'mask_detector_platform_interface.dart';

/// An implementation of [MaskDetectorPlatform] that uses method channels.
class MethodChannelMaskDetector extends MaskDetectorPlatform {

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.lengdev.maskdetector');


  @override
  Future<Map<String, dynamic>> initialize() async {
    try {
      // Don't cast directly - let Flutter handle the type conversion
      final result = await methodChannel.invokeMethod('initialize');

      if(result == null) throw MaskDetectorException("Failed to initialize mask detector!.");
      
      return  Map<String, dynamic>.from(result);
      
    } on PlatformException catch (e) {
      print("PlatformException: ${e.message}"); // Debug log
      throw MaskDetectorException(
        'Failed to initialize: ${e.message}',
        code: e.code,
        details: e.details,
      );
    } catch (e) {
      print("Unknown error: $e"); // Debug log
      throw MaskDetectorException('Unexpected error: $e');
    }
  }
  
  @override
  Future<MaskDetectionResult> detectMask(Uint8List yuvBytes,{
    required double imageWidth,
    required double imageHeight,
    required Rect faceCountour,
    required int rotation,
  }) async {
    
    try {
      final rawResult = await methodChannel.invokeMethod('detectMask', {
        'yuvBytes': yuvBytes,
        "imageWidth": imageWidth.toInt(),
        "imageHeight": imageHeight.toInt(),
        "rotation": rotation,
        "faceContour": {
          "left": faceCountour.left.toInt(),
          "top": faceCountour.top.toInt(),
          "right": faceCountour.right.toInt(),
          "bottom": faceCountour.bottom.toInt(),
        }
      });

      if (rawResult == null) {
        throw MaskDetectorException('Failed to detect mask!.');
      }

      // Convert to Map<String, dynamic>
      final result = (rawResult as Map).cast<String, dynamic>();

      return MaskDetectionResult(
        hasMask: result["hasMask"] as bool,
        withMaskScore: result["withMaskScore"] as double,
        withoutMaskScore: result["withoutMaskScore"] as double,
      );
    } on PlatformException catch (e) {
      throw MaskDetectorException(
        'Prediction failed: ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }
  
  

  @override
  Future<Map<String,dynamic>> destroy() async {
    try {
      final result =  await methodChannel.invokeMethod<Map>('destroy');
      if(result == null) throw MaskDetectorException("Failed to detroy mask detector!.");
      return  Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      throw MaskDetectorException(
        'Destroy : ${e.message}',
        code: e.code,
        details: e.details,
      );
    }
  }


}
