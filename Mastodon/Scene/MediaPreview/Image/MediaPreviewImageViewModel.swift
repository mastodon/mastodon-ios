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
import MastodonCore

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
    
    public enum ImagePreviewItem {
        case remote(RemoteImageContext)
        case local(LocalImageContext)
    }
    
    public struct RemoteImageContext {
        let assetURL: URL?
        let thumbnail: UIImage?
        let altText: String?
    }
    
    public struct LocalImageContext {
        let image: UIImage
    }

}
