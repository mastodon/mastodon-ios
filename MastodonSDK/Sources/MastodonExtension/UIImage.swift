//
//  UIImage.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/8.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

extension UIImage {
    public static func placeholder(
        size: CGSize = CGSize(width: 1, height: 1),
        color: UIColor,
        cornerRadius: CGFloat = 0
    ) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)

        return render.image { (context: UIGraphicsImageRendererContext) in
            // set clear fill
            context.cgContext.setFillColor(color.cgColor)
            
            let rect = CGRect(origin: .zero, size: size)
            
            // clip corner if needs
            if cornerRadius > 0 {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).cgPath
                context.cgContext.addPath(path)
                context.cgContext.clip(using: .evenOdd)
            }
            
            // set fill
            context.fill(rect)
        }
    }
}

// refs: https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
extension UIImage {
    @available(iOS 14.0, *)
    public var dominantColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }

        let filter = CIFilter.areaAverage()
        filter.inputImage = inputImage
        filter.extent = inputImage.extent
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)

        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}

extension UIImage {
    public var domainLumaCoefficientsStyle: UIUserInterfaceStyle? {
        guard let brightness = cgImage?.brightness else { return nil }
        return brightness > 100 ? .light : .dark // 0 ~ 255
    }
}

extension UIImage {
    public func blur(radius: CGFloat) -> UIImage? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = inputImage
        blurFilter.radius = Float(radius)
        guard let outputImage = blurFilter.outputImage else { return nil }
        guard let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) else { return nil }
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
        return image
    }
}

extension UIImage {
    public func withRoundedCorners(radius: CGFloat? = nil) -> UIImage? {
        let maxRadius = min(size.width, size.height) / 2
        let cornerRadius: CGFloat = {
            guard let radius = radius, radius > 0 else { return maxRadius }
            return min(radius, maxRadius)
        }()

        let render = UIGraphicsImageRenderer(size: size)
        return render.image { (_: UIGraphicsImageRendererContext) in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius).addClip()
            draw(in: rect)
        }
    }
}

extension UIImage {
    public static func adaptiveUserInterfaceStyleImage(lightImage: UIImage, darkImage: UIImage) -> UIImage {
        let imageAsset = UIImageAsset()
        imageAsset.register(lightImage, with: UITraitCollection(traitsFrom: [
            UITraitCollection(displayScale: 1.0),
            UITraitCollection(userInterfaceStyle: .light)
        ]))
        imageAsset.register(darkImage, with: UITraitCollection(traitsFrom: [
            UITraitCollection(displayScale: 1.0),
            UITraitCollection(userInterfaceStyle: .dark)
        ]))
        return imageAsset.image(with: UITraitCollection.current)
    }
}
