//
//  StatusContentCacheService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-17.
//

import UIKit
import Combine

final class StatusContentCacheService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let cache = NSCache<Key, ParseResultWrapper>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.BlurhashImageCacheService.working-queue", qos: .userInitiated, attributes: .concurrent)
    
    func parseResult(content: String, emojiDict: MastodonStatusContent.EmojiDict) -> MastodonStatusContent.ParseResult? {
        let key = Key(content: content, emojiDict: emojiDict)
        return cache.object(forKey: key)?.parseResult
    }
    
    func prefetch(content: String, emojiDict: MastodonStatusContent.EmojiDict) {
        let key = Key(content: content, emojiDict: emojiDict)
        guard cache.object(forKey: key) == nil else { return }
        MastodonStatusContent.parseResult(content: content, emojiDict: emojiDict)
            .sink { [weak self] parseResult in
                guard let self = self else { return }
                guard let parseResult = parseResult else { return }
                let wrapper = ParseResultWrapper(parseResult: parseResult)
                self.cache.setObject(wrapper, forKey: key)
            }
            .store(in: &disposeBag)
    }

}

extension StatusContentCacheService {
    class Key: NSObject {
        let content: String
        let emojiDict: MastodonStatusContent.EmojiDict
        
        init(content: String, emojiDict: MastodonStatusContent.EmojiDict) {
            self.content = content
            self.emojiDict = emojiDict
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? Key else { return false }
            return object.content == content
                && object.emojiDict == emojiDict
        }
        
        override var hash: Int {
            return content.hashValue ^
                emojiDict.hashValue
        }
    }
    
    class ParseResultWrapper: NSObject {
        let parseResult: MastodonStatusContent.ParseResult
        
        init(parseResult: MastodonStatusContent.ParseResult) {
            self.parseResult = parseResult
        }
        
        override func isEqual(_ object: Any?) -> Bool {
            guard let object = object as? ParseResultWrapper else { return false }
            return object.parseResult == parseResult
        }
        
        override var hash: Int {
            return parseResult.hashValue
        }
    }
}
