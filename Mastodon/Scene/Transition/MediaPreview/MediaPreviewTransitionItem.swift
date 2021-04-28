//
//  MediaPreviewTransitionItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

class MediaPreviewTransitionItem: Identifiable {
    
    let id: UUID
    
    // TODO:
    var imageView: UIImageView?
    var snapshotRaw: UIView?
    var snapshotTransitioning: UIView?
    var initialFrame: CGRect? = nil
    var targetFrame: CGRect? = nil
    var touchOffset: CGVector = CGVector.zero

    init(id: UUID) {
        self.id = id
    }
    
}
