//
//  PlaceholderImageCacheService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-16.
//

import UIKit
import AlamofireImage

public final class PlaceholderImageCacheService {
    
    let cache = NSCache<Key, UIImage>()
    
    func image(color: UIColor, size: CGSize, cornerRadius: CGFloat = 0) -> UIImage {
        let key = Key(color: color, size: size, cornerRadius: cornerRadius)
        guard let image = cache.object(forKey: key) else {
            var image = UIImage.placeholder(size: size, color: color)
            if cornerRadius < size.width * 0.5 {
                image = image
                    .af.imageAspectScaled(toFill: size)
                    .af.imageRounded(withCornerRadius: cornerRadius, divideRadiusByImageScale: false)
            } else {
                image = image.af.imageRoundedIntoCircle()
            }
            cache.setObject(image, forKey: key)
            return image
        }
        
        return image
    }
    
}

extension PlaceholderImageCacheService {
    class Key: NSObject {
        let color: UIColor
        let size: CGSize
        let cornerRadius: CGFloat
        
        init(color: UIColor, size: CGSize, cornerRadius: CGFloat) {
            self.color = color
            self.size = size
            self.cornerRadius = cornerRadius
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? Key else { return false }
            return object.color == color
                && object.size == size
                && object.cornerRadius == cornerRadius
        }
        
        override var hash: Int {
            return color.hashValue ^
                size.width.hashValue ^
                size.height.hashValue ^
                cornerRadius.hashValue
        }
    }
}
