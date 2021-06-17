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
        let key = Key(blurhash: blurhash, size: size, url: url)
        
        if let image = self.cache.object(forKey: key) {
            return Just(image).eraseToAnyPublisher()
        }

        return Future { promise in
            self.workingQueue.async {
                guard let image = BlurhashImageCacheService.blurhashImage(blurhash: blurhash, size: size, url: url) else {
                    promise(.success(nil))
                    return
                }
                self.cache.setObject(image, forKey: key)
                promise(.success(image))
            }
        }
        .receive(on: RunLoop.main)
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
    class Key: NSObject {
        let blurhash: String
        let size: CGSize
        let url: URL
        
        init(blurhash: String, size: CGSize, url: URL) {
            self.blurhash = blurhash
            self.size = size
            self.url = url
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? Key else { return false }
            return object.blurhash == blurhash
                && object.size == size
                && object.url == url
        }
        
        override var hash: Int {
            return blurhash.hashValue ^
                size.width.hashValue ^
                size.height.hashValue ^
                url.hashValue
        }

    }
}
