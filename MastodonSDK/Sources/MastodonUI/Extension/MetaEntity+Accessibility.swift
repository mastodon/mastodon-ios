//
//  MetaEntity+Accessibility.swift
//  
//
//  Created by Jed Fox on 2022-11-03.
//

import Meta

extension Meta.Entity {
    var accessibilityCustomActionLabel: String? {
        switch meta {
        case .url(_, trimmed: _, url: let url, userInfo: _):
            return "Link: \(url)"
        case .hashtag(_, hashtag: let hashtag, userInfo: _):
            return "Hashtag \(hashtag)"
        case .mention(_, mention: let mention, userInfo: _):
            return "Show Profile: @\(mention)"
        case .email(let email, userInfo: _):
            return "Email address: \(email)"
        // emoji are not actionable
        case .emoji:
            return nil
        }
    }
}
