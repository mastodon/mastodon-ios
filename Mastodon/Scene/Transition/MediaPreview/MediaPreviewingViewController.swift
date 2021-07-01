//
//  MediaPreviewingViewController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import Foundation

protocol MediaPreviewingViewController: AnyObject {
    func isInteractiveDismissible() -> Bool
}
