//
//  BlurhashImageCacheService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-16.
//

import UIKit
import Combine

final class BlurhashImageCacheService {
    
    let cache = NSCache<Key, UIImage>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.BlurhashImageCacheService.working-queue", qos: .userInitiated, attributes: .concurrent)
    
    func image(blurhash: String, size: CGSize, url: URL) -> AnyPublisher<UIImage?, Never> {
        return Future { promise in
            self.workingQueue.async {
                let key = Key(blurhash: blurhash, size: size, url: url)
                guard let image = self.cache.object(forKey: key) else {
                    if let image = BlurhashImageCacheService.blurhashImage(blurhash: blurhash, size: size, url: url) {
                        self.cache.setObject(image, forKey: key)
                        promise(.success(image))
                    } else {
                        promise(.success(nil))
                    }
                    return
                }
                promise(.success(image))
            }
        }
        .eraseToAnyPublisher()
    }
    
    static func blurhashImage(blurhash: String, size: CGSize, url: URL) -> UIImage? {
        let imageSize: CGSize = {
            let aspectRadio = size.width / size.height
            if size.width > size.height {
                let width: CGFloat = MosaicMeta.edgeMaxLength
                let height = width / aspectRadio
                return CGSize(width: width, height: height)
            } else {
                let height: CGFloat = MosaicMeta.edgeMaxLength
                let width = height * aspectRadio
                return CGSize(width: width, height: height)
            }
        }()
        
        let image = UIImage(blurHash: blurhash, size: imageSize)

        return image
    }

}

extension BlurhashImageCacheService {
    class Key: Hashable {
        static func == (lhs: BlurhashImageCacheService.Key, rhs: BlurhashImageCacheService.Key) -> Bool {
            return lhs.blurhash == rhs.blurhash
                && lhs.size == rhs.size
                && lhs.url == rhs.url
        }
        
        let blurhash: String
        let size: CGSize
        let url: URL
        
        init(blurhash: String, size: CGSize, url: URL) {
            self.blurhash = blurhash
            self.size = size
            self.url = url
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(blurhash)
            hasher.combine(size.width)
            hasher.combine(size.height)
            hasher.combine(url)
        }
    }
}
