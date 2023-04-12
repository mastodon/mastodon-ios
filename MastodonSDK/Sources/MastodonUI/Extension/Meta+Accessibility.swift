//
//  MetaEntity+Accessibility.swift
//  
//
//  Created by Jed Fox on 2022-11-03.
//

import Meta
import MastodonLocalization
import Foundation

extension Meta {
    public var accessibilityLabel: String? {
        switch self {
        case .url(_, trimmed: _, url: let url, userInfo: _):
            return L10n.Common.Controls.Status.MetaEntity.url(url)
        case .hashtag(_, hashtag: let hashtag, userInfo: _):
            return L10n.Common.Controls.Status.MetaEntity.hashtag(hashtag)
        case .mention(_, mention: let mention, userInfo: _):
            return L10n.Common.Controls.Status.MetaEntity.mention(mention)
        case .email(let email, userInfo: _):
            return L10n.Common.Controls.Status.MetaEntity.email(email)
        // emoji are not actionable
        case .emoji:
            return nil
        }
    }
}

extension MetaContent {
    public var accessibilityLabel: String {
        return entities.reversed().reduce(string) { string, entity in
            if case .emoji(_, let shortcode, _, _) = entity.meta {
                return (string as NSString).replacingCharacters(in: entity.range, with: ":" + shortcode + ":")
            }
            return string
        } as String
    }
}
