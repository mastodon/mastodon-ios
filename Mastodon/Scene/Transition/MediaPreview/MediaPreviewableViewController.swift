//
//  MediaPreviewableViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import Foundation

protocol MediaPreviewableViewController: class {
    var mediaPreviewTransitionController: MediaPreviewTransitionController { get }
}
