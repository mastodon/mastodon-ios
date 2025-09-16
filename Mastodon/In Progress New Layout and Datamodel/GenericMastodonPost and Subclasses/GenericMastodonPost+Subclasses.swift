// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension GenericMastodonPost {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> GenericMastodonPost {
        if let reblog = status.reblog {
            return MastodonBoostPost(id: status.id, metaData: PostMetadata.fromStatus(status), boostedPost: GenericMastodonPost.fromStatus(reblog) as! MastodonContentPost, _legacyEntity: status)
        }
        else {
            let quoted: MastodonQuotedPost?
            if let quote = status.quote {
                quoted = MastodonQuotedPost(quoted: quote)
            } else {
                quoted = nil
            }
            return MastodonBasicPost(id: status.id, metaData: PostMetadata.fromStatus(status), content: PostContent.fromStatus(status), inReplyTo: InReplyToDetails.fromStatus(status), attachment: PostAttachment.fromStatus(status), quoted: quoted, _legacyEntity: status)
        }
    }
    
}

extension GenericMastodonPost {
    func byReplacingActionablePost(with updatedPost: GenericMastodonPost) throws -> GenericMastodonPost {
        if let basicPost = self as? MastodonBasicPost {
            guard basicPost.id == updatedPost.id else {
                throw PostActionFailure.postIdMismatch }
            return updatedPost
        } else if let boostPost = self as? MastodonBoostPost {
            guard boostPost.boostedPost.id == updatedPost.id, let updatedPost = updatedPost as? MastodonContentPost else {
                throw PostActionFailure.postIdMismatch }
            return MastodonBoostPost(id: boostPost.id, metaData: boostPost.metaData, boostedPost: updatedPost, _legacyEntity: _legacyEntity)
        } else {
            assertionFailure("not implemented")
            return self
        }
    }
}

public class MastodonContentPost: GenericMastodonPost {
    let content: GenericMastodonPost.PostContent
    
    init(id: Mastodon.Entity.Status.ID, metaData: GenericMastodonPost.PostMetadata, content: GenericMastodonPost.PostContent, _legacyEntity: Mastodon.Entity.Status) {
        self.content = content
        super.init(id: id, metaData: metaData, _legacyEntity: _legacyEntity)
    }
    
    enum CodingKeys: String, CodingKey {
        case content
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let content = try container.decode(GenericMastodonPost.PostContent.self, forKey: .content)
        self.content = content
        try super.init(from: decoder)
    }
}

class MastodonBasicPost: MastodonContentPost {
    let inReplyTo: GenericMastodonPost.InReplyToDetails?
    let attachment: GenericMastodonPost.PostAttachment?
    let quotedPost: MastodonQuotedPost?
    
    init(id: Mastodon.Entity.Status.ID, metaData: GenericMastodonPost.PostMetadata, content: GenericMastodonPost.PostContent, inReplyTo: GenericMastodonPost.InReplyToDetails?, attachment: GenericMastodonPost.PostAttachment?, quoted: MastodonQuotedPost?, _legacyEntity: Mastodon.Entity.Status) {
        self.inReplyTo = inReplyTo
        self.attachment = attachment
        self.quotedPost = quoted
        super.init(id: id, metaData: metaData, content: content, _legacyEntity: _legacyEntity)
    }
    
    enum CodingKeys: String, CodingKey {
        case inReplyTo
        case attachment
        case quotedPost
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let inReplyTo = try container.decode(GenericMastodonPost.InReplyToDetails.self, forKey: .inReplyTo)
        let attachment = try container.decode(GenericMastodonPost.PostAttachment.self, forKey: .attachment)
        let quoted = try container.decode(MastodonQuotedPost.self, forKey: .quotedPost)
        self.inReplyTo = inReplyTo
        self.attachment = attachment
        self.quotedPost = quoted
        try super.init(from: decoder)
    }
}

class MastodonBoostPost: GenericMastodonPost {
    let boostedPost: MastodonContentPost
    
    init(id: Mastodon.Entity.Status.ID, metaData: GenericMastodonPost.PostMetadata, boostedPost: MastodonContentPost, _legacyEntity: Mastodon.Entity.Status) {
        self.boostedPost = boostedPost
        super.init(id: id, metaData: metaData, _legacyEntity: _legacyEntity)
    }
    
    enum CodingKeys: String, CodingKey {
        case boostedPost
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boostedPost = try container.decode(MastodonContentPost.self, forKey: .boostedPost)
        self.boostedPost = boostedPost
        try super.init(from: decoder)
    }
}

class MastodonQuotedPost: Codable {
    let state: Mastodon.Entity.Quote.AcceptanceState
    let fullPost: MastodonContentPost?
    let quotedPostID: Mastodon.Entity.Status.ID?
    
    init(quoted: Mastodon.Entity.Quote) {
        self.state = quoted.state
        if let fullStatus = quoted.quotedStatus, let post = MastodonContentPost.fromStatus(fullStatus) as? MastodonContentPost {
            self.fullPost = post
        } else {
            self.fullPost = nil
        }
        self.quotedPostID = quoted.quotedStatus?.id ?? quoted.quotedStatusID
    }

    enum CodingKeys: String, CodingKey {
        case state
        case fullPost
        case quotedPostID
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let state = try container.decode(Mastodon.Entity.Quote.AcceptanceState.self, forKey: .state)
        let quotedPost = try container.decode(MastodonContentPost.self, forKey: .fullPost)
        let quotedPostID = try container.decode(String.self, forKey: .quotedPostID)
        self.state = state
        self.fullPost = quotedPost
        self.quotedPostID = quotedPostID
    }
}

extension String {
    var strippingQuoteInline: String {
        return trimmingPrefix(quoteInlineRegex)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

let quoteInlineRegex = /<p\s+class="quote-inline">[\s\S]*?<\/p>/
