//
//  MastodonMentionContainer.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import Foundation
import CoreDataStack
import MastodonSDK

public protocol MastodonMentionContainer {
    var mentions: [Mastodon.Entity.Mention]? { get }
}

extension MastodonMentionContainer {
    public var mastodonMentions: [MastodonMention] {
        return mentions.flatMap { mentions in
            mentions.map { MastodonMention(mention: $0) }
        } ?? []
    }
}

extension Mastodon.Entity.Status: MastodonMentionContainer { }
