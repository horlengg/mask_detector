import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mask_detector_example/camera_stream_payload.dart';
import 'package:mask_detector_example/device_manager.dart';
import 'package:mask_detector_example/image_utils.dart';


class CameraView extends StatefulWidget {
  const CameraView({
      super.key,
      required this.customPaint,
      required this.onImage,
      this.onCameraFeedReady,
      this.onDetectorViewModeChanged,
      this.onCameraLensDirectionChanged,
      this.cameraStreamProcessDelay = const Duration(seconds: 1),
      this.skipFrame
    });

  final CustomPaint? customPaint;
  final Function(CameraStreamPayload payload) onImage;
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;
  final Duration cameraStreamProcessDelay;
  final bool Function()? skipFrame;

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> with SingleTickerProviderStateMixin {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _changingCameraLens = false;
  int _cameraIndex = 1;
  Size cameraViewSize = const Size(0.0, 0.0);
  double cameraRatio = 1.0;
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  bool _isProcessingImage = false;
  double? _defaultApplicationBrightness;

  @override
  void initState() {
    super.initState();
    _checkApplicationBrightness();
    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    _startLiveFeed(_cameras[_cameraIndex]);
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
    resetApplicationBrightness();
  }


  @override
  Widget build(BuildContext context) {
    if (
      _cameras.isEmpty ||
      _controller == null ||
      _controller?.value.isInitialized == false
    ) {
      return Container();
    }
    if(_changingCameraLens) return const Text("Loading...");

    return LayoutBuilder(
      builder: (context, constraints) {
        final localWidth = constraints.maxWidth;
        final cameraWidth  = _controller!.value.previewSize?.width ?? 0;
        final cameraHeight  = _controller!.value.previewSize?.height ?? 0;
        cameraViewSize = Size(cameraWidth, cameraHeight);
        cameraRatio = _controller!.value.aspectRatio;
        return CustomPaint(
          painter: CornerPainter(),
          child: SizedBox(
            width: localWidth > 300 ? 300 : localWidth,
            height: localWidth > 300 ? 300 : localWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(500),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: cameraViewSize.height,
                  height: cameraViewSize.width,
                  child: CameraPreview(_controller!,child: widget.customPaint)
                )
              )
            ),
          ),
        );
      }
    );
  }

  Future switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    await _stopLiveFeed();
    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _startLiveFeed(_cameras[_cameraIndex]);
    setState(() => _changingCameraLens = false);
  }

  
  Future _startLiveFeed(CameraDescription camera) async {
    
    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
      // _checkApplicationBrightness();
    });
  }

  Future _stopLiveFeed() async {
    print("_stopLiveFeed().... ");
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {

    if(
      _isProcessingImage || 
      widget.skipFrame?.call() == true ||
      _controller == null || 
      !_controller!.value.isInitialized
    ) {
      return;
    }

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null || !mounted) return;

    final rotation = _getCameraRotation();

    final yuvBytes = ImageUtils.convertForPlatform(image);
    
    
    final payload = CameraStreamPayload(
      inputImage  : inputImage,
      yuvBytes    : yuvBytes,
      imageWidth  : image.width,
      imageHeight : image.height,
      rotation    : rotation,
      cameraImage : image,
      bytesPerRow : image.planes[0].bytesPerRow
    );
    widget.onImage(payload);

    _isProcessingImage = true;
    Timer(widget.cameraStreamProcessDelay, () {
      _isProcessingImage = false;
    });
  }

  Future<void> _checkApplicationBrightness() async {
    try {
      final brightness = await DeviceManager.getApplicationBrightness();
      _defaultApplicationBrightness ??= brightness;
      log("Current brightness: $brightness");
      // Ensure minimum brightness level for visibility
      const double minBrightness = 0.1;
      if (brightness < minBrightness) {
        await DeviceManager.setApplicationBrightness(minBrightness);
        log("Brightness adjusted to $minBrightness for visibility");
      }
    } catch (e, s) {
      log("Error checking brightness: $e", stackTrace: s);
    }
  }

  void resetApplicationBrightness() {
    final defaultBrightness = _defaultApplicationBrightness;
    if (defaultBrightness != null) {
      DeviceManager.setApplicationBrightness(defaultBrightness);
      log("Brightness reset to default: $defaultBrightness");
    } else {
      log("No default brightness stored; nothing to reset.");
    }
  }


  int _getCameraRotation() {
    final camera = _cameras[_cameraIndex];
    return camera.sensorOrientation;
  }
  
  // InputImage? _inputImageFromCameraImage(CameraImage image) {
  //   final camera = _cameras[_cameraIndex];
  //   final sensorOrientation = camera.sensorOrientation;

  //   // Determine rotation
  //   InputImageRotation? rotation;
  //   if (Platform.isIOS) {
  //     rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
  //   } else if (Platform.isAndroid) {
  //     final deviceOrientation = _controller!.value.deviceOrientation;
      
  //     var rotationCompensation = _orientations[deviceOrientation] ?? 0;
      
  //     if (camera.lensDirection == CameraLensDirection.front) {
  //       rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
  //     } else {
  //       rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
  //     }
  //     rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
  //   }
    
  //   if (rotation == null) {
  //     return null;
  //   }

  //   if (Platform.isAndroid) {
  //     final WriteBuffer allBytes = WriteBuffer();
  //     for (final Plane plane in image.planes) {
  //       allBytes.putUint8List(plane.bytes);
  //     }
  //     final bytes = allBytes.done().buffer.asUint8List();

  //     return InputImage.fromBytes(
  //       bytes: bytes,
  //       metadata: InputImageMetadata(
  //         size: Size(image.width.toDouble(), image.height.toDouble()),
  //         rotation: rotation,
  //         format: InputImageFormat.nv21,
  //         bytesPerRow: image.planes[0].bytesPerRow,
  //       ),
  //     );
  //   }

  //   // iOS – use bgra8888
  //   final format = InputImageFormatValue.fromRawValue(image.format.raw);
  //   if (format != InputImageFormat.bgra8888 || image.planes.length != 1) {
  //     print('iOS format issue: format=$format, planes=${image.planes.length}');
  //     return null;
  //   }
  //   final plane = image.planes.first;

  //   return InputImage.fromBytes(
  //     bytes: plane.bytes,
  //     metadata: InputImageMetadata(
  //       size: Size(image.width.toDouble(), image.height.toDouble()),
  //       rotation: rotation,
  //       format: format!,
  //       bytesPerRow: plane.bytesPerRow,
  //     ),
  //   );
  // }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;

    // Determine rotation
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      final deviceOrientation = _controller!.value.deviceOrientation;
      
      var rotationCompensation = _orientations[deviceOrientation] ?? 0;
      
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) {
      return null;
    }

    if (Platform.isAndroid) {
      final int width = image.width;
      final int height = image.height;
      
      // Get plane data
      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];
      
      final yRowStride = yPlane.bytesPerRow;
      final uvRowStride = uPlane.bytesPerRow;
      final uvPixelStride = uPlane.bytesPerPixel ?? 2;
      
      // Calculate the actual data size (without padding)
      // final int ySize = width * height;
      // final int uvSize = (width ~/ 2) * (height ~/ 2);
      
      final WriteBuffer buffer = WriteBuffer();
      
      // Copy Y plane - handle stride/padding
      for (int row = 0; row < height; row++) {
        final int offset = row * yRowStride;
        final int end = offset + width;
        if (end <= yPlane.bytes.length) {
          buffer.putUint8List(yPlane.bytes.sublist(offset, end));
        }
      }
      
      // Copy UV planes - interleave V and U for NV21 format
      // Handle stride and pixel stride
      for (int row = 0; row < height ~/ 2; row++) {
        for (int col = 0; col < width ~/ 2; col++) {
          final int offset = row * uvRowStride + col * uvPixelStride;
          if (offset < vPlane.bytes.length && offset < uPlane.bytes.length) {
            buffer.putUint8(vPlane.bytes[offset]); // V first for NV21
            buffer.putUint8(uPlane.bytes[offset]); // then U
          }
        }
      }
      
      final bytes = buffer.done().buffer.asUint8List();

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(width.toDouble(), height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.nv21,
          bytesPerRow: width, // Use actual width, not stride
        ),
      );
    }

    // iOS – use bgra8888
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format != InputImageFormat.bgra8888 || image.planes.length != 1) {
      print('iOS format issue: format=$format, planes=${image.planes.length}');
      return null;
    }
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

}


class CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.lightBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const double cornerLength = 30;

    // top-left
    canvas.drawLine(Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(0, cornerLength), paint);

    // top-right
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width, cornerLength), paint);

    // bottom-left
    canvas.drawLine(Offset(0, size.height),
        Offset(0, size.height - cornerLength), paint);
    canvas.drawLine(Offset(0, size.height),
        Offset(cornerLength, size.height), paint);

    // bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}