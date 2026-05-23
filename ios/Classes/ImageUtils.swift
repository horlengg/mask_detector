//
//  ImageUtils.swift
//  Runner
//
//  Created by Houleng Ly on 23/5/26.
//

class ImageUtils {
    static func bgraToUIImage(_ data: Data, width: Int, height: Int, bytesPerRow: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let provider = CGDataProvider(data: data as CFData),
              let cgImage = CGImage(
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bitsPerPixel: 32,
                  bytesPerRow: bytesPerRow,
                  space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue:
                      CGImageAlphaInfo.noneSkipFirst.rawValue |
                      CGBitmapInfo.byteOrder32Little.rawValue),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: false,
                  intent: .defaultIntent
              ) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    static func yuv420ToBitmap(_ data: Data, width: Int, height: Int) -> UIImage? {
      var dataVar = data
      return dataVar.withUnsafeMutableBytes { ptr -> UIImage? in
        guard let base = ptr.baseAddress else { return nil }
        let yPlaneSize = width * height
        guard data.count >= yPlaneSize else { return nil }

        var argbPixels = [UInt8](repeating: 255, count: width * height * 4)

        for row in 0 ..< height {
          for col in 0 ..< width {
            let yIndex  = row * width + col
            let uvIndex = yPlaneSize + (row / 2) * width + (col & ~1)

            guard yIndex < data.count, uvIndex + 1 < data.count else { continue }

            let y = Int(data[yIndex])
            let v = Int(data[uvIndex])     - 128
            let u = Int(data[uvIndex + 1]) - 128

            let r = (y + Int(1.370705 * Float(v))).clamped(0, 255)
            let g = (y - Int(0.698001 * Float(v)) - Int(0.337633 * Float(u))).clamped(0, 255)
            let b = (y + Int(1.732446 * Float(u))).clamped(0, 255)

            let pixel = (row * width + col) * 4
            argbPixels[pixel]     = UInt8(r)
            argbPixels[pixel + 1] = UInt8(g)
            argbPixels[pixel + 2] = UInt8(b)
            argbPixels[pixel + 3] = 255
          }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
          data: &argbPixels,
          width: width, height: height,
          bitsPerComponent: 8,
          bytesPerRow: width * 4,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cgImage = ctx.makeImage() else { return nil }

        return UIImage(cgImage: cgImage)
      }
    }

    static func rotateBitmap(_ image: UIImage, degrees: Int) -> UIImage? {
      guard degrees != 0 else { return image }
      let radians = CGFloat(degrees) * .pi / 180

      let newSize: CGSize
      switch degrees {
      case 90, 270: newSize = CGSize(width: image.size.height, height: image.size.width)
      default:      newSize = image.size
      }

      UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
      defer { UIGraphicsEndImageContext() }

      guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
      ctx.translateBy(x: newSize.width / 2, y: newSize.height / 2)
      ctx.rotate(by: radians)
      image.draw(in: CGRect(
        x: -image.size.width / 2,
        y: -image.size.height / 2,
        width: image.size.width,
        height: image.size.height
      ))
      return UIGraphicsGetImageFromCurrentImageContext()
    }

    static func cropBitmap(_ image: UIImage, rect: CGRect) -> UIImage? {
      guard let cgImage = image.cgImage else { return nil }

      let imgW = CGFloat(cgImage.width)
      let imgH = CGFloat(cgImage.height)

      let x = rect.minX.clamped(0, imgW - 1)
      let y = rect.minY.clamped(0, imgH - 1)
      let w = rect.width.clamped(1, imgW - x)
      let h = rect.height.clamped(1, imgH - y)

      guard let cropped = cgImage.cropping(to: CGRect(x: x, y: y, width: w, height: h)) else {
        return nil
      }
      return UIImage(cgImage: cropped)
    }
    
    
}


private extension Comparable {
  func clamped(_ lo: Self, _ hi: Self) -> Self {
    min(max(self, lo), hi)
  }
}

