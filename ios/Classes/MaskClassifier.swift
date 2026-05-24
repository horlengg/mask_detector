//
//  MaskClassifier.swift
//  MaskDetectionApp
//
//  Created by Houleng Ly on 18/5/26.
//

import Foundation
import TensorFlowLite
import UIKit
import CoreImage

class MaskClassifier {
    private var interpreter: Interpreter?

    let inputSize = 224

    init() {
        loadModel()
    }

    private func loadModel() {
        do {
            let bundle = Bundle(for: MaskDetectorPlugin.self)
            let resourceBundle = bundle.url(forResource: "mask_detector", withExtension: "bundle")
                .flatMap { Bundle(url: $0) } ?? bundle

            guard let modelPath = resourceBundle.path(
                forResource: "mask_detector_v2",
                ofType: "tflite"
            ) else { 
                print("mask_detector_v2.tflite not found")
                return
            }
            var options = Interpreter.Options()
            options.threadCount = 2
            let interp = try Interpreter(modelPath: modelPath, options: options)
            try interp.allocateTensors()
            let inputTensor = try interp.input(at: 0)
            interpreter = interp
        } catch let error as InterpreterError {
            print("❌ Interpreter error: \(error.localizedDescription)")
        } catch {
            print("❌ Unexpected error loading model: \(error)")
        }
    }

    func predict(image: UIImage) -> MaskResponse? {
        guard let interpreter = interpreter else {
            print("Interpreter not loaded")
            return nil
        }
        guard let pixelBuffer = preprocessImage(image) else { return nil }

        do {
            let startAt = Date()

            try interpreter.copy(pixelBuffer, toInputAt: 0)
            try interpreter.invoke()

            let outputTensor = try interpreter.output(at: 0)
            let results: [Float] = outputTensor.data.withUnsafeBytes {
                Array($0.bindMemory(to: Float.self))
            }
            print("results : \(results)")
            return MaskResponse(
                mask: results[0],
                withoutMask: results[1],
                durationInMilliseconds: Date().timeIntervalSince(startAt) * 1000
            )
        } catch {
            print("Inference error: \(error)")
            return nil
        }
    }

    private func preprocessImage(_ image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else {
            print("No cgImage")
            return nil
        }
        
        let width = inputSize
        let height = inputSize
        let bytesPerRow = width * 4

        var rawBytes = [UInt8](repeating: 0, count: bytesPerRow * height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: &rawBytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            print("CGContext failed")
            return nil
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var floatData = [Float]()
        floatData.reserveCapacity(width * height * 3)

        for i in 0 ..< width * height {
            let base = i * 4
            floatData.append((Float(rawBytes[base])     - 127.5) / 127.5)  // R
            floatData.append((Float(rawBytes[base + 1]) - 127.5) / 127.5)  // G
            floatData.append((Float(rawBytes[base + 2]) - 127.5) / 127.5)  // B
        }

        return Data(bytes: floatData, count: floatData.count * MemoryLayout<Float>.size)
    }
}

struct MaskResponse {
    var mask: Float
    var withoutMask: Float
    var durationInMilliseconds: TimeInterval
}
