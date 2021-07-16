//
//  UIImage.swift
//  
//
//  Created by MainasuK Cirno on 2021-7-16.
//

import UIKit

extension UIImage {
    public static func placeholder(size: CGSize = CGSize(width: 1, height: 1), color: UIColor) -> UIImage {
        let render = UIGraphicsImageRenderer(size: size)

        return render.image { (context: UIGraphicsImageRendererContext) in
            context.cgContext.setFillColor(color.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
