//
//  MediaPreviewableViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

protocol MediaPreviewableViewController: AnyObject {
    var mediaPreviewTransitionController: MediaPreviewTransitionController { get }
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect?
}

extension MediaPreviewableViewController {
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect? {
        switch transitionItem.source {
        case .mosaic(let mosaicImageViewContainer):
            guard index < mosaicImageViewContainer.imageViews.count else { return nil }
            let imageView = mosaicImageViewContainer.imageViews[index]
            return imageView.superview!.convert(imageView.frame, to: nil)
        case .profileAvatar(let profileHeaderView):
            return profileHeaderView.avatarImageView.superview!.convert(profileHeaderView.avatarImageView.frame, to: nil)
        case .profileBanner:
            return nil      // fallback to snapshot.frame
        }
    }
}
