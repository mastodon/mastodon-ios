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
        metadata.originalURL = url
        configureMetadata(metadata)
    }

    let url: URL
    let metadata: LPLinkMetadata

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
}
