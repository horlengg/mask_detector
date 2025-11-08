import 'dart:io';

import 'package:face_contour_detector/face_contour_detector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_detector/mask_detector.dart';
import 'package:mask_detector/models/mask_detection_result.dart';
import 'package:mask_detector/models/mask_detector_exception.dart';
import 'package:image/image.dart' as img;

void main() {
  runApp(const MaterialApp(
    home: MaskDetectorExample(),
  ));
}

class MaskDetectorExample extends StatefulWidget {
  
  const MaskDetectorExample({super.key});

  @override
  State<MaskDetectorExample> createState() => _MaskDetectorExampleState();
}

class _MaskDetectorExampleState extends State<MaskDetectorExample> {
  
  bool _isInitialized = false;
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  Rect? _faceContour;
  Size? _selectedImageSize;
  MaskDetectionResult? _result;
  String? _duration;
  
  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }
  
  void _initializeDetector() async {
    try {
      await MaskDetector.initialize();
      await FaceContourDetector.initialize();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }finally{
      setState(() {});
    }
  }
  void _handlePickImageAndDetect() async {

    setState(() {
      _selectedImage = null;
      _duration = null;
      _result = null;
    });

    final file = await _picker.pickImage(source: ImageSource.gallery);
    if(file == null) return;
    try {
      _selectedImage = File(file.path);
      final bytes = await file.readAsBytes();
      final decodeImg = img.decodeImage(bytes);
      _selectedImageSize = Size(decodeImg!.width.toDouble(), decodeImg.height.toDouble());
      final startAt = DateTime.now();
      final faceContours = await FaceContourDetector.detectFromImage(bytes);
      if(faceContours.isNotEmpty){
        final face = faceContours.first;
        _faceContour = face;
        final yuvBytes = _convertToYuv420(decodeImg);
        if(yuvBytes == null) throw Exception("yuvBytes is null");
        _result = await MaskDetector.detect(
          yuvBytes, 
          imageHeight: decodeImg.height.toDouble(),
          imageWidth: decodeImg.width.toDouble(),
          faceCountour: face,
          rotation: 0
        );
        print(_result);
      }
      _duration = "Duration : ${DateTime.now().difference(startAt).inMilliseconds} ms";
        print(_duration);
    } on MaskDetectorException catch (e){
      print(e.what());
      _duration = null;
      _result = null;
    }
    catch (e) {
      print("Error : ${e}");
      _duration = null;
      _result = null;
    }finally{
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    MaskDetector.destroy();
    FaceContourDetector.destroy();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mask Detector'),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: !_isInitialized ? 
              Text("Failed to initialize detector!.") :
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _handlePickImageAndDetect, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15,horizontal: 25)
                    ),
                    child: Text("Pick Image")
                  ),
                  if(_selectedImage != null)
                    Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 40),
                          decoration: BoxDecoration(
                            border: Border.all(width: 2, color: Colors.lightGreenAccent)
                          ),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _selectedImageSize!.width,
                              height: _selectedImageSize!.height,
                              child: Stack(
                                children: [
                                  Image.file(
                                    _selectedImage!,
                                    width: _selectedImageSize!.width,
                                    height: _selectedImageSize!.height,
                                    fit: BoxFit.fill,
                                  ),
                                  CustomPaint(
                                    size: _selectedImageSize!,
                                    painter: FaceBoxPainter(_faceContour!, _selectedImageSize!),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          color: Colors.black,
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _result.toString(),
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 20),
                              Text(_duration ?? "",style: TextStyle(color: Colors.lightGreenAccent),)
                            ],
                          ),
                        )
                      ],
                    )
                ],
              ),
          ),
        ),
      ),
    );
  }
}


class FaceBoxPainter extends CustomPainter {
  final Rect rect;
  final Size size;

  FaceBoxPainter(this.rect, this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant FaceBoxPainter oldDelegate) {
    return rect != oldDelegate.rect || size != oldDelegate.size;
  }
}

Uint8List? _convertToYuv420(img.Image image) {
  try {
    final int width = image.width;
    final int height = image.height;
    
    // Ensure even dimensions for YUV420
    final int evenWidth = width - (width % 2);
    final int evenHeight = height - (height % 2);
    
    print("Original: ${width}x${height}, Adjusted: ${evenWidth}x${evenHeight}");
    
    // Calculate correct buffer size for YUV420
    final int yPlaneSize = evenWidth * evenHeight;
    final int uvPlaneSize = (evenWidth ~/ 2) * (evenHeight ~/ 2);
    final int totalSize = yPlaneSize + uvPlaneSize * 2;
    
    final Uint8List yuv = Uint8List(totalSize);
    
    // Y plane conversion (use even dimensions)
    int yIndex = 0;
    for (int y = 0; y < evenHeight; y++) {
      for (int x = 0; x < evenWidth; x++) {
        final pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();
        
        // Convert RGB to Y (luminance)
        final int yValue = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
        yuv[yIndex++] = yValue.clamp(0, 255);
      }
    }
    
    // U and V plane conversion with proper subsampling
    int uIndex = yPlaneSize;
    int vIndex = yPlaneSize + uvPlaneSize;
    
    for (int y = 0; y < evenHeight; y += 2) {
      for (int x = 0; x < evenWidth; x += 2) {
        final pixel = image.getPixel(x, y);
        final int r = pixel.r.toInt();
        final int g = pixel.g.toInt();
        final int b = pixel.b.toInt();
        
        final int uValue = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
        final int vValue = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
        
        yuv[uIndex++] = uValue.clamp(0, 255);
        yuv[vIndex++] = vValue.clamp(0, 255);
      }
    }
    
    print("YUV conversion successful: ${evenWidth}x${evenHeight}, totalSize=$totalSize");
    return yuv;
    
  } catch (e) {
    print("Error convert bytes image to yuvBytes : $e");
    return null;
  }
}