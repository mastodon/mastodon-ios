//
//  MediaPreviewImageViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

class MediaPreviewImageViewModel {
    // input
    let item: ImagePreviewItem
    
    init(item: ImagePreviewItem) {
        self.item = item
    }
    
}

extension MediaPreviewImageViewModel {
    
    public struct ImagePreviewItem {
        let assetURL: URL?
        let thumbnail: UIImage?
        let altText: String?
    }

}
