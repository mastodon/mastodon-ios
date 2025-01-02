//
//  MediaPreviewableViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

protocol MediaPreviewableViewController: UIViewController {
    var mediaPreviewTransitionController: MediaPreviewTransitionController { get }
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> SourceFrameProvider?
}

struct SourceFrameProvider {
    let containerSourceFrame: CGRect
    let contentSourceFrame: CGRect?
}

extension MediaPreviewableViewController {
    func sourceFrame(transitionItem: MediaPreviewTransitionItem, index: Int) -> SourceFrameProvider? {
        var sourceFrameProvider: SourceFrameProvider?
        switch transitionItem.source {
        case .attachment(let mediaView):
            if let superview = mediaView.superview {
                sourceFrameProvider = SourceFrameProvider(
                    containerSourceFrame: superview.convert(mediaView.frame, to: nil),
                    contentSourceFrame: mediaView.contentView().frame
                )
            }
        case .attachments(let mediaGridContainerView):
            guard index < mediaGridContainerView.mediaViews.count else { break }
            let mediaView = mediaGridContainerView.mediaViews[index]
            if let superview = mediaView.superview {
                sourceFrameProvider = SourceFrameProvider(
                    containerSourceFrame: superview.convert(mediaView.frame, to: nil),
                    contentSourceFrame: mediaView.contentView().frame
                )
            }
        case .profileAvatar(let profileHeaderView):
            if let superview = profileHeaderView.avatarButton.superview {
                let rect = superview.convert(profileHeaderView.avatarButton.frame, to: nil)
                sourceFrameProvider = SourceFrameProvider(
                    containerSourceFrame: rect, contentSourceFrame: nil
                )
            }
        case .profileBanner(let profileHeaderView):
            if let superview = profileHeaderView.bannerImageView.superview {
                let rect = superview.convert(profileHeaderView.bannerImageView.frame, to: nil)
                sourceFrameProvider = SourceFrameProvider(
                    containerSourceFrame: rect, contentSourceFrame: nil
                )
            }
        }

        return sourceFrameProvider
    }
}
