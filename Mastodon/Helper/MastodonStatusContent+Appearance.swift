//
//  MastodonStatusContent+Appearance.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-6-20.
//

import UIKit

extension MastodonStatusContent {
    struct Appearance {
        let attributes: [NSAttributedString.Key: Any]
        let urlAttributes: [NSAttributedString.Key: Any]
        let hashtagAttributes: [NSAttributedString.Key: Any]
        let mentionAttributes: [NSAttributedString.Key: Any]
    }
}
