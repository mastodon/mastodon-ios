//
//  MediaPreviewTransitionViewController.swift
//  TwidereX
//
//  Created by MainasuK on 2021-12-8.
//  Copyright © 2021 Twidere. All rights reserved.
//

import UIKit

protocol MediaPreviewTransitionViewController: UIViewController {
    var mediaPreviewTransitionContext: MediaPreviewTransitionContext? { get }
}


struct MediaPreviewTransitionContext {
    let transitionView: UIView
    let snapshot: UIView
    let snapshotTransitioning: UIView
}
