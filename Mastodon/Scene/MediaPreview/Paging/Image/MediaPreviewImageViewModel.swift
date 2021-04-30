//
//  MediaPreviewImageViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import Combine
import AlamofireImage

class MediaPreviewImageViewModel {
    
    // input
    let item: ImagePreviewItem
    
    // output
    let image: CurrentValueSubject<UIImage?, Never>
        
    init(meta: RemoteImagePreviewMeta) {
        self.item = .status(meta)
        self.image = CurrentValueSubject(meta.thumbnail)
        
        let url = meta.url
        ImageDownloader.default.download(URLRequest(url: url), completion:  { [weak self] response in
            guard let self = self else { return }
            switch response.result {
            case .failure(let error):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s fail: %s", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription, error.localizedDescription)
            case .success(let image):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: download image %s success", ((#file as NSString).lastPathComponent), #line, #function, url.debugDescription)
                self.image.value = image
            }
        })
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
        self.image = CurrentValueSubject(meta.image)
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
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
    
}
