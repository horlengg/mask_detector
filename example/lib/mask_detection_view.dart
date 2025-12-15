

import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:mask_detector/mask_detector.dart';
import 'package:mask_detector/models/mask_detection_result.dart';
import 'package:mask_detector_example/camera_stream_payload.dart';
import 'package:mask_detector_example/camera_view.dart';
import 'package:mask_detector_example/face_detector_painter.dart';



class MaskDetectionView extends StatefulWidget {
  const MaskDetectionView({super.key});

  @override
  State<MaskDetectionView> createState() => _MaskDetectionViewState();
}

class _MaskDetectionViewState extends State<MaskDetectionView> {

  MaskDetectionResult? _maskResult;
  Size? _screenSize;
  late FaceDetector _faceDetector;
  bool isNoFaceDetected = true;
  bool _maskDetectorInitialized = false;
  CustomPaint? _customPaint;
  bool _isWidgetDestroyed = false;
  String? _processDuration;


  final GlobalKey<CameraViewState> _cameraViewKey = GlobalKey();

  void _handleDetectMask(CameraStreamPayload payload) async {
    
    if(_isWidgetDestroyed) return;
    
    final startAt = DateTime.now();
    try {

      final faces = await _faceDetector.processImage(payload.inputImage);
      if(faces.isEmpty) {
        isNoFaceDetected = true;
        throw Exception("No face detected");
      }

      isNoFaceDetected = false;

      final bx = faces[0].boundingBox;

      final faceContour = Rect.fromLTRB(bx.left, bx.top, bx.right,bx.bottom);

      final painter = FaceDetectorPainter(
        faces,
        Size(payload.cameraImage.width.toDouble(), payload.cameraImage.height.toDouble()),
        payload.inputImage.metadata!.rotation,
        CameraLensDirection.front
      );
      _customPaint = CustomPaint(painter: painter);

      _maskResult = await MaskDetector.detect(
        payload.yuvBytes,
        imageWidth: payload.imageWidth.toDouble(),
        imageHeight: payload.imageHeight.toDouble(),
        faceCountour: faceContour,
        rotation: payload.rotation
      );
      log("data : $_maskResult");
      _processDuration = "${DateTime.now().difference(startAt).inMilliseconds} ms";
    }
    catch (e){
      _maskResult = null;
      _processDuration = null;
      log("Error while detect mask : $e");
    } finally {
      setState(() {});
    }
  }

  void _initDetection() async {
    
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.3
      ),
    );

    final result = await MaskDetector.initialize();
    _maskDetectorInitialized = result['status'] ?? false;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initDetection();
  }

  @override
  void dispose() {
    _isWidgetDestroyed = true;
    super.dispose();
    MaskDetector.destroy();
    _faceDetector.close();
  }


  @override
  Widget build(BuildContext context) {

    if(!_maskDetectorInitialized) {
      return Scaffold(
        body: Center(
          child: Text("Failed to initialize mask detector!."),
        ),
      );
    }

    _screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Sample Mask Detection",style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Color(0xFFC7D9E9),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Mask Detection",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey,
                letterSpacing: 2
              ),
            ),
            const SizedBox(height: 50),
            Center(
              child: SizedBox(
                width: _screenSize!.width * .9,
                height: _screenSize!.width * .9,
                child: CameraView(
                  key: _cameraViewKey,
                  onImage: _handleDetectMask,
                  customPaint: _customPaint,
                  cameraStreamProcessDelay: const Duration(milliseconds: 200),
                ),
              ),
            ),
            const SizedBox(height: 40),
            _buildResponse()
          ],
        ),
      ),
    );
  }
  Widget _buildResponse(){
    if(isNoFaceDetected){
      return Text(
        "No face detected!.",
        style: TextStyle(
          color: Colors.red,
          fontSize: 20
        ),
    );
    }
    if(_maskResult == null) return SizedBox.shrink();
    String msg = _maskResult!.hasMask ? "Has Mask" : "No Mask";
    Color color = _maskResult!.hasMask ? Colors.red : Colors.green;
    return Column(
      children: [
        Text(
          msg,
          style: TextStyle(
            color: color,
            fontSize: 20
          ),
        ),
        Text(
          "Confidence Score : ${_maskResult!.hasMask ? _maskResult!.withMaskScore : _maskResult!.withoutMaskScore}",
          style: TextStyle(
            color: color
          ),
        ),
        if(_processDuration != null)
          Text(
            "Duration : $_processDuration",
            style: TextStyle(color: Colors.green),
          )
      ],
    );
  }
}