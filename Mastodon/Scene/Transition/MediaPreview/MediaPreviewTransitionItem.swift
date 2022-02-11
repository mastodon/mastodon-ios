//
//  MediaPreviewTransitionItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit
import CoreData
import MastodonUI

class MediaPreviewTransitionItem: Identifiable {
    
    let id: UUID
    let source: Source
    var previewableViewController: MediaPreviewableViewController
    
    // source
    var image: UIImage?
    var aspectRatio: CGSize?
    var initialFrame: CGRect? = nil
    var sourceImageView: UIImageView?
    var sourceImageViewCornerRadius: CGFloat?
    
    // target
    var targetFrame: CGRect? = nil
    
    // transitioning
    var transitionView: UIView?
    var snapshotRaw: UIView?
    var snapshotTransitioning: UIView?
    var touchOffset: CGVector = CGVector.zero
    var interactiveTransitionMaskView: UIView?
    var interactiveTransitionMaskLayer: CAShapeLayer?

    init(
        id: UUID = UUID(),
        source: Source,
        previewableViewController: MediaPreviewableViewController
    ) {
        self.id = id
        self.source = source
        self.previewableViewController = previewableViewController
    }
    
}

extension MediaPreviewTransitionItem {
    enum Source {
        case attachment(MediaView)
        case attachments(MediaGridContainerView)
        case profileAvatar(ProfileHeaderView)
        case profileBanner(ProfileHeaderView)
        
        func updateAppearance(position: UIViewAnimatingPosition, index: Int?) {
            let alpha: CGFloat = position == .end ? 1 : 0
            switch self {
            case .attachment(let mediaView):
                mediaView.alpha = alpha
            case .attachments(let mediaGridContainerView):
                if let index = index {
                    mediaGridContainerView.setAlpha(alpha, index: index)
                } else {
                    mediaGridContainerView.setAlpha(alpha)
                }
            case .profileAvatar(let profileHeaderView):
                profileHeaderView.avatarButton.alpha = alpha
            case .profileBanner:
                break    // keep source
            }
        }
    }
}
