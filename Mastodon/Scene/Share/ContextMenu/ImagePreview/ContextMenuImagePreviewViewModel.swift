//
//  ContextMenuImagePreviewViewModel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-30.
//

import UIKit
import Combine

final class ContextMenuImagePreviewViewModel {
    
    var disposeBag = Set<AnyCancellable>()
    
    // input
    let aspectRatio: CGSize
    let thumbnail: UIImage?
    let url = CurrentValueSubject<URL?, Never>(nil)
    
    init(aspectRatio: CGSize, thumbnail: UIImage?) {
        self.aspectRatio = aspectRatio
        self.thumbnail = thumbnail
    }
    
}
