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
        
    init(meta: StatusImagePreviewMeta) {
        self.item = .status(meta)
    }
    
    init(meta: LocalImagePreviewMeta) {
        self.item = .local(meta)
    }
    
}

extension MediaPreviewImageViewModel {
    enum ImagePreviewItem {
        case status(StatusImagePreviewMeta)
        case local(LocalImagePreviewMeta)
    }
    
    struct StatusImagePreviewMeta {
        let url: URL
        let thumbnail: UIImage?
    }
    
    struct LocalImagePreviewMeta {
        let image: UIImage
    }
    
}
