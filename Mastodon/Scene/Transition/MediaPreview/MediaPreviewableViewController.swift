//
//  MediaPreviewableViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

protocol MediaPreviewableViewController: UIViewController {
    var mediaPreviewTransitionController: MediaPreviewTransitionController { get }
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect?
}

extension MediaPreviewableViewController {
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> CGRect? {
        switch transitionItem.source {
        case .attachment(let mediaView):
            return mediaView.superview?.convert(mediaView.frame, to: nil)
        case .attachments(let mediaGridContainerView):
            guard index < mediaGridContainerView.mediaViews.count else { return nil }
            let mediaView = mediaGridContainerView.mediaViews[index]
            return mediaView.superview?.convert(mediaView.frame, to: nil)
        case .profileAvatar(let profileHeaderView):
            return profileHeaderView.avatarButton.superview?.convert(profileHeaderView.avatarButton.frame, to: nil)
        case .profileBanner(let profileHeaderView):
            return profileHeaderView.bannerImageView.superview?.convert(profileHeaderView.bannerImageView.frame, to: nil)
        }
    }
    
    func sourceView(transitionItem: MediaPreviewTransitionItem, index: Int) -> UIView? {
        switch transitionItem.source {
        case .attachment(let mediaView):
            return mediaView
        case .attachments(let mediaGridContainerView):
            guard index < mediaGridContainerView.mediaViews.count else { return nil }
            return mediaGridContainerView.mediaViews[index]
        case .profileAvatar(let profileHeaderView):
            return profileHeaderView.avatarButton
        case .profileBanner(let profileHeaderView):
            return profileHeaderView.bannerImageView
        }
    }
}
