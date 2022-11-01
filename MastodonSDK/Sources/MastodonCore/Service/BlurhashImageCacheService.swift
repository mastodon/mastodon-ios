//
//  BlurhashImageCacheService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-16.
//

import UIKit
import Combine

public final class BlurhashImageCacheService {
    
    // MARK: - Singleton
    public static let shared = BlurhashImageCacheService()
    
    static let edgeMaxLength: CGFloat = 20
    
    let cache = NSCache<Key, UIImage>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.BlurhashImageCacheService.working-queue", qos: .userInitiated, attributes: .concurrent)
    
    public func image(
        blurhash: String,
        size: CGSize,
        url: String
    ) -> AnyPublisher<UIImage?, Never> {
        let key = Key(blurhash: blurhash, size: size, url: url)
        
        if let image = self.cache.object(forKey: key) {
            return Just(image).eraseToAnyPublisher()
        }

        return Future { promise in
            self.workingQueue.async {
                guard let image = BlurhashImageCacheService.blurhashImage(blurhash: blurhash, size: size) else {
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
    
    static func blurhashImage(blurhash: String, size: CGSize) -> UIImage? {
        let imageSize: CGSize = {
            let aspectRadio = size.width / size.height
            if size.width > size.height {
                let width: CGFloat = BlurhashImageCacheService.edgeMaxLength
                let height = width / aspectRadio
                return CGSize(width: width, height: height)
            } else {
                let height: CGFloat = BlurhashImageCacheService.edgeMaxLength
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
        let url: String
        
        init(blurhash: String, size: CGSize, url: String) {
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
