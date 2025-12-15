
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

ElevatedButton buildButton(String title,void Function()? tap){
  return ElevatedButton(
    onPressed: tap, 
    style: ElevatedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 15),
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0))
    ),
    child: Text(title)
  );
}

class CameraYUVConverter {
  /// Converts CameraImage to NV21 bytes (what your native code expects)
  static Uint8List convertToNV21(CameraImage image, {bool debug = false}) {
    
    if (Platform.isAndroid) {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToNV21(image, debug: debug);
      } else if (image.format.group == ImageFormatGroup.nv21) {
        return _convertNV21Direct(image, debug: debug);
      } else {
        throw UnsupportedError('Unsupported Android format: ${image.format.group}');
      }
    } else if (Platform.isIOS) {
      return _convertBGRA8888ToNV21(image, debug: debug);
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Android: When format is already NV21 - just concatenate
  static Uint8List _convertNV21Direct(CameraImage image, {bool debug = false}) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = (width * height) ~/ 2;
    
    if (debug) {
      print('NV21 Direct conversion');
      print('Expected - Y: $ySize, UV: $uvSize');
    }
    
    final Uint8List nv21 = Uint8List(ySize + uvSize);
    
    final yPlane = image.planes[0];
    final uvPlane = image.planes[1];
    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uvPlane.bytesPerRow;
    
    // Copy Y plane (handle stride)
    int nv21Index = 0;
    for (int row = 0; row < height; row++) {
      int offset = row * yRowStride;
      for (int col = 0; col < width; col++) {
        nv21[nv21Index++] = yPlane.bytes[offset + col];
      }
    }
    
    // Copy UV plane (handle stride)
    int uvHeight = height ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      int offset = row * uvRowStride;
      for (int col = 0; col < width; col++) {
        nv21[nv21Index++] = uvPlane.bytes[offset + col];
      }
    }
    
    return nv21;
  }

  /// Android: Convert YUV420 (3 planes) to NV21 (interleaved VU)
  static Uint8List _convertYUV420ToNV21(CameraImage image, {bool debug = false}) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = (width * height) ~/ 2;
    
    if (debug) {
      print('YUV420 to NV21 conversion');
      print('Expected - Y: $ySize, UV: $uvSize, Total: ${ySize + uvSize}');
    }
    
    final Uint8List nv21 = Uint8List(ySize + uvSize);
    
    // Copy Y plane (handle stride/padding)
    final yPlane = image.planes[0];
    final yRowStride = yPlane.bytesPerRow;
    
    int nv21Index = 0;
    for (int row = 0; row < height; row++) {
      int offset = row * yRowStride;
      for (int col = 0; col < width; col++) {
        nv21[nv21Index++] = yPlane.bytes[offset + col];
      }
    }
    
    if (debug) {
      print('Y plane copied: $nv21Index bytes');
    }
    
    // Interleave U and V planes into VU format (NV21)
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uRowStride = uPlane.bytesPerRow;
    final vRowStride = vPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    
    final int uvHeight = height ~/ 2;
    final int uvWidth = width ~/ 2;
    
    if (debug) {
      print('UV dimensions: ${uvWidth}x${uvHeight}');
      print('U rowStride: $uRowStride, pixelStride: $uvPixelStride');
      print('V rowStride: $vRowStride');
    }
    
    for (int row = 0; row < uvHeight; row++) {
      int uRowOffset = row * uRowStride;
      int vRowOffset = row * vRowStride;
      
      for (int col = 0; col < uvWidth; col++) {
        // Handle pixel stride - UV planes may be interleaved already
        int uIndex = uRowOffset + col * uvPixelStride;
        int vIndex = vRowOffset + col * uvPixelStride;
        
        // NV21 is VU interleaved (V first, then U)
        nv21[nv21Index++] = vPlane.bytes[vIndex]; // V
        nv21[nv21Index++] = uPlane.bytes[uIndex]; // U
      }
    }
    
    if (debug) {
      print('Total written: $nv21Index bytes (expected: ${ySize + uvSize})');
      
      if (nv21Index != ySize + uvSize) {
        print('⚠️ WARNING: Size mismatch! Expected ${ySize + uvSize}, got $nv21Index');
      } else {
        print('✅ Conversion successful!');
      }
    }
    
    return nv21;
  }

  /// iOS: Convert BGRA8888 to NV21
  static Uint8List _convertBGRA8888ToNV21(CameraImage image, {bool debug = false}) {
    final int width = image.width;
    final int height = image.height;
    final int expectedSize = (width * height * 3) ~/ 2;
    
    if (debug) {
      print('BGRA to NV21 - Expected size: $expectedSize');
    }
    
    final Uint8List nv21 = Uint8List(expectedSize);
    final Uint8List bgra = image.planes[0].bytes;
    final int bytesPerRow = image.planes[0].bytesPerRow;
    final int bytesPerPixel = 4; // BGRA = 4 bytes
    
    int yIndex = 0;
    int uvIndex = width * height;
    
    // Convert BGRA to YUV
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final int offset = row * bytesPerRow + col * bytesPerPixel;
        
        final int b = bgra[offset];
        final int g = bgra[offset + 1];
        final int r = bgra[offset + 2];
        
        // Calculate Y (luminance)
        final int y = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
        nv21[yIndex++] = y.clamp(0, 255);
        
        // Calculate U and V for every 2x2 block (subsample)
        if (row % 2 == 0 && col % 2 == 0 && uvIndex < expectedSize - 1) {
          final int u = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
          final int v = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
          
          // NV21 format: VU interleaved
          nv21[uvIndex++] = v.clamp(0, 255);
          nv21[uvIndex++] = u.clamp(0, 255);
        }
      }
    }
    
    if (debug) {
      print('Y written: $yIndex, UV written: ${uvIndex - width * height}');
    }
    
    return nv21;
  }
}