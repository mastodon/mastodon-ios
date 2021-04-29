//
//  MediaPreviewImageViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import Combine

class MediaPreviewImageViewModel {
    
    // input
    let item: ImagePreviewItem
        
    init(meta: RemoteImagePreviewMeta) {
        self.item = .status(meta)
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
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
