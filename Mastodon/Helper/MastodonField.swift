//
//  MastodonField.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import Foundation
import ActiveLabel

enum MastodonField {

    @available(*, deprecated, message: "rely on server meta rendering")
    static func parse(field string: String, emojiDict: MastodonStatusContent.EmojiDict) -> ParseResult {
        // use content parser get emoji entities
        let value = string
        
        var string = string
        var entities: [ActiveEntity] = []

        do {
            let contentParseresult = try MastodonStatusContent.parse(content: string, emojiDict: emojiDict)
            string = contentParseresult.trimmed
            entities.append(contentsOf: contentParseresult.activeEntities)
        } catch {
            // assertionFailure(error.localizedDescription)
        }
        
        let mentionMatches = string.matches(pattern: "(?:@([a-zA-Z0-9_]+)(@[a-zA-Z0-9_.-]+)?)")
        let hashtagMatches = string.matches(pattern: "(?:#([^\\s.]+))")
        let urlMatches = string.matches(pattern: "(?i)https?://\\S+(?:/|\\b)")
        
        
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
        
        return ParseResult(value: value, trimmed: string, activeEntities: entities)
    }
    
}

extension MastodonField {
    struct ParseResult {
        let value: String
        let trimmed: String
        let activeEntities: [ActiveEntity]
    }
}
