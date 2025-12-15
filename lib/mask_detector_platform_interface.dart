
import 'package:flutter/services.dart';
import 'package:mask_detector/models/mask_detection_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mask_detector_method_channel.dart';

abstract class MaskDetectorPlatform extends PlatformInterface {
  /// Constructs a MaskDetectorPlatform.
  MaskDetectorPlatform() : super(token: _token);

  static final Object _token = Object();

  static MaskDetectorPlatform _instance = MethodChannelMaskDetector();

  /// The default instance of [MaskDetectorPlatform] to use.
  ///
  /// Defaults to [MethodChannelMaskDetector].
  static MaskDetectorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MaskDetectorPlatform] when
  /// they register themselves.
  static set instance(MaskDetectorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Map<String,dynamic>> initialize(){
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<MaskDetectionResult> detectMask(Uint8List yuvBytes,{
    required double imageWidth,
    required double imageHeight,
    required Rect faceCountour,
    required int rotation,
  }){
    throw UnimplementedError('detectMask() has not been implemented.');
  }


  Future<Map<String,dynamic>> destroy() {
    throw UnimplementedError('destroy() has not been implemented.');
  }
  
}
