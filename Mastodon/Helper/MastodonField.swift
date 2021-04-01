//
//  MastodonField.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import Foundation
import ActiveLabel

enum MastodonField {
    
    static func parse(field string: String) -> ParseResult {
        let mentionMatches = string.matches(pattern: "(?:@([a-zA-Z0-9_]+))")
        let hashtagMatches = string.matches(pattern: "(?:#([^\\s.]+))")
        let urlMatches = string.matches(pattern: "(?i)https?://\\S+(?:/|\\b)")
        
        var entities: [ActiveEntity] = []
        
        for match in mentionMatches {
            guard let text = string.substring(with: match, at: 0) else { continue }
            let entity = ActiveEntity(range: match.range, type: .mention(text, userInfo: nil))
            entities.append(entity)
        }
        
        for match in hashtagMatches {
            guard let text = string.substring(with: match, at: 0) else { continue }
            let entity = ActiveEntity(range: match.range, type: .hashtag(text, userInfo: nil))
            entities.append(entity)
        }
        
        for match in urlMatches {
            guard let text = string.substring(with: match, at: 0) else { continue }
            let entity = ActiveEntity(range: match.range, type: .url(text, trimmed: text, url: text, userInfo: nil))
            entities.append(entity)
        }
        
        return ParseResult(value: string, activeEntities: entities)
    }
    
}

extension MastodonField {
    struct ParseResult {
        let value: String
        let activeEntities: [ActiveEntity]
    }
}
