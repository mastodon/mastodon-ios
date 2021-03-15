//
//  NeedsDependency+AVPlayerViewControllerDelegate.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/3/10.
//

import Foundation
import AVKit

extension NeedsDependency where Self: AVPlayerViewControllerDelegate {
    
    func handlePlayerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        context.videoPlaybackService.playerViewModel(for: playerViewController)?.isFullScreenPresentationing = true
    }
    
    func handlePlayerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        context.videoPlaybackService.playerViewModel(for: playerViewController)?.isFullScreenPresentationing = false
    }

}
