//
//  MaskDetectorPlugin.swift
//  Runner
//
//  Created by Houleng Ly on 23/5/26.
//
import Flutter
import UIKit

public class MaskDetectorPlugin: NSObject, FlutterPlugin {

  private var classifier: MaskClassifier?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.lengdev.maskdetector",
      binaryMessenger: registrar.messenger()
    )
    let instance = MaskDetectorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "initialize":  handleInitialize(result: result)
    case "detectMask":  handleDetectMask(call: call, result: result)
    case "destroy":     handleDestroy(result: result)
    default:            result(FlutterMethodNotImplemented)
    }
  }

  private func handleInitialize(result: @escaping FlutterResult) {
    DispatchQueue.global(qos: .userInitiated).async {
      self.classifier = MaskClassifier()
      let success = self.classifier != nil
      DispatchQueue.main.async {
        if success {
          result([
            "status" : true,
            "message" : "Initialize mask detector success!."
          ])
        } else {
          result(FlutterError(
            code: "INIT_FAILED",
            message: "Failed to load mask_detector.tflite",
            details: nil
          ))
        }
      }
    }
  }


  private func handleDestroy(result: @escaping FlutterResult) {
    classifier = nil
    result([
      "status" : true,
      "message" : "Mask detector was destroyed!."
    ])
    
  }
    
  private func handleDetectMask(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let classifier = classifier else {
      result(FlutterError(code: "NOT_INITIALIZED", message: "Call initialize() first", details: nil))
      return
    }

    guard
      let args       = call.arguments as? [String: Any],
      let yuvBytes   = args["yuvBytes"]   as? FlutterStandardTypedData,
      let width      = args["imageWidth"] as? Int,
      let height     = args["imageHeight"] as? Int,
      let bytesPerRow = args["bytesPerRow"] as? Int,
      let rectMap    = args["faceContour"] as? [String: Int],
      let rectLeft   = rectMap["left"],
      let rectTop    = rectMap["top"],
      let rectRight  = rectMap["right"],
      let rectBottom = rectMap["bottom"]
    else {
        result(FlutterError(code: "INVALID_ARGS", message: "Required: yuvBytes, width, height, rotation, rect{left,top,right,bottom}", details: nil))
        return
    }


    DispatchQueue.global(qos: .userInitiated).async {
        guard let bitmap = ImageUtils.bgraToUIImage(yuvBytes.data, width: width, height: height, bytesPerRow: bytesPerRow) else {
            DispatchQueue.main.async {
              result(FlutterError(code: "PREPROCESS_FAILED", message: "Could not decode image", details: nil))
            }
            return
        }
        
        
        let rect = CGRect(x: rectLeft, y: rectTop, width: rectRight - rectLeft, height: rectBottom - rectTop)
        let cropped = ImageUtils.cropBitmap(bitmap, rect: rect)

      guard let response = classifier.predict(image: cropped!) else {
        DispatchQueue.main.async {
          result(FlutterError(code: "INFERENCE_FAILED", message: "Model inference returned nil", details: nil))
        }
        return
      }

      let hasMask = response.mask > response.withoutMask

      DispatchQueue.main.async {
          result([
            "hasMask":          hasMask,
            "withMaskScore":    response.mask,
            "withoutMaskScore": response.withoutMask,
            "durationInMilliseconds": response.durationInMilliseconds
          ])
      }
    }
  }
}



