//
//  UIImage.swift
//  
//
//  Created by MainasuK on 2022-5-6.
//

import UIKit

extension UIImage {
    
    public func resized(size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
