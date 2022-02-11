//
//  ContextMenuImagePreviewViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-30.
//

import UIKit

final class ContextMenuImagePreviewViewModel {
        
    // input
    let assetURL: URL
    let thumbnail: UIImage?
    let aspectRatio: CGSize
    
    init(
        assetURL: URL,
        thumbnail: UIImage?,
        aspectRatio: CGSize
    ) {
        self.assetURL = assetURL
        self.aspectRatio = aspectRatio
        self.thumbnail = thumbnail
    }
    
}
