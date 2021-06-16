//
//  PlaceholderImageCacheService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-16.
//

import UIKit
import AlamofireImage

final class PlaceholderImageCacheService {
    
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
    class Key: Hashable {
        let color: UIColor
        let size: CGSize
        let cornerRadius: CGFloat
        
        init(color: UIColor, size: CGSize, cornerRadius: CGFloat) {
            self.color = color
            self.size = size
            self.cornerRadius = cornerRadius
        }
        
        static func == (lhs: PlaceholderImageCacheService.Key, rhs: PlaceholderImageCacheService.Key) -> Bool {
            return lhs.color == rhs.color
                && lhs.size == rhs.size
                && lhs.cornerRadius == rhs.cornerRadius
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(color)
            hasher.combine(size.width)
            hasher.combine(size.height)
            hasher.combine(cornerRadius)
        }
    }
}
