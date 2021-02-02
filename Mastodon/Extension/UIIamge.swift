//
//  UIIamge.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/28.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    
    static func placeholder(size: CGSize = CGSize(width: 1, height: 1), color: UIColor) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)
        
        return render.image { (context: UIGraphicsImageRendererContext) in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    
}

// refs: https://www.hackingwithswift.com/example-code/media/how-to-read-the-average-color-of-a-uiimage-using-ciareaaverage
extension UIImage {
    @available(iOS 14.0, *)
    var dominantColor: UIColor? {
        guard let inputImage = CIImage(image: self) else { return nil }
        
        let filter = CIFilter.areaAverage()
        filter.inputImage = inputImage
        filter.extent = inputImage.extent
        guard let outputImage = filter.outputImage else { return nil }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull])
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        
        return UIColor(red: CGFloat(bitmap[0]) / 255, green: CGFloat(bitmap[1]) / 255, blue: CGFloat(bitmap[2]) / 255, alpha: CGFloat(bitmap[3]) / 255)
    }
}
