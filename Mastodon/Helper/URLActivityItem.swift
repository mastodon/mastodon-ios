//
//  URLActivityItem.swift
//  Mastodon
//
//  Created by Jed Fox on 2022-12-03.
//

import UIKit
import LinkPresentation

class URLActivityItem: NSObject, UIActivityItemSource {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return url
    }
}
