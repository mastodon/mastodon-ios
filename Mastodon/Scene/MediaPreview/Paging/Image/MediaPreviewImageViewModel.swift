//
//  MediaPreviewImageViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine
import Alamofire
import AlamofireImage
import FLAnimatedImage

class MediaPreviewImageViewModel {

    var disposeBag = Set<AnyCancellable>()
    
    // input
    let item: ImagePreviewItem
    
    // output
    let image: CurrentValueSubject<(UIImage?, FLAnimatedImage?), Never>
    let altText: String?
        
    init(meta: RemoteImagePreviewMeta) {
        self.item = .status(meta)
        self.image = CurrentValueSubject((meta.thumbnail, nil))
        self.altText = meta.altText
        
        let url = meta.url
        AF.request(url).publishData()
            .map { response in
                switch response.result {
                case .success(let data):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                    let image = UIImage(data: data, scale: UIScreen.main.scale)
                    let animatedImage = FLAnimatedImage(animatedGIFData: data)
                    return (image, animatedImage)
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
                    return (nil, nil)
                }
            }
            .assign(to: \.value, on: image)
            .store(in: &disposeBag)
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
        self.image = CurrentValueSubject((meta.image, nil))
        self.altText = nil
    }
    
}

extension MediaPreviewImageViewModel {
    enum ImagePreviewItem {
        case status(RemoteImagePreviewMeta)
        case local(LocalImagePreviewMeta)
        
        var activityItems: [Any] {
            var items: [Any] = []
            
            switch self {
            case .status(let meta):
                items.append(meta.url)
            case .local(let meta):
                items.append(meta.image)
            }
            
            return items
        }
    }
    
    struct RemoteImagePreviewMeta {
        let url: URL
        let thumbnail: UIImage?
        let altText: String?
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
    
}
