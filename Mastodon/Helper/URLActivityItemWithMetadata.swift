//
//  URLActivityItemWithMetadata.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-12-03.
//

import UIKit
import LinkPresentation

class URLActivityItemWithMetadata: NSObject, UIActivityItemSource {
    init(url: URL, configureMetadata: (LPLinkMetadata) -> Void) {
        self.url = url
        self.metadata = LPLinkMetadata()
        metadata.url = url
        configureMetadata(metadata)
    }

    let url: URL
    let metadata: LPLinkMetadata

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        metadata
    }
}
