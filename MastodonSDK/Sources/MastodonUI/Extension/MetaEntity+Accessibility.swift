//
//  MetaEntity+Accessibility.swift
//  
//
//  Created by Jed Fox on 2022-11-03.
//

import Meta
import MastodonLocalization

extension Meta.Entity {
    var accessibilityCustomActionLabel: String? {
        switch meta {
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
