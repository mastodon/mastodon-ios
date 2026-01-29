//
//  UIImage.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/8.
//

import CoreImage
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
