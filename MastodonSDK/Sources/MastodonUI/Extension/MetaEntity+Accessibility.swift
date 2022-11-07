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
            // TODO: i18n (a11y.meta_entity.url)
            return "Link: \(url)"
        case .hashtag(_, hashtag: let hashtag, userInfo: _):
            // TODO: i18n (a11y.meta_entity.hashtag)
            return "Hashtag \(hashtag)"
        case .mention(_, mention: let mention, userInfo: _):
            // TODO: i18n (a11y.meta_entity.mention)
            return "Show Profile: \("@" + mention)"
        case .email(let email, userInfo: _):
            // TODO: i18n (a11y.meta_entity.email)
            return "Email address: \(email)"
        // emoji are not actionable
        case .emoji:
            return nil
        }
    }
}
