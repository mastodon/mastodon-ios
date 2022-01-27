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
    let context: AppContext
    let item: ImagePreviewItem
    
    init(context: AppContext, item: ImagePreviewItem) {
        self.context = context
        self.item = item
    }
    
}

extension MediaPreviewImageViewModel {
    
    enum ImagePreviewItem {
        case remote(RemoteImageContext)
        case local(LocalImageContext)
    }
    
    struct RemoteImageContext {
        let assetURL: URL?
        let thumbnail: UIImage?
        let altText: String?
    }
    
    struct LocalImageContext {
        let image: UIImage
    }

}
