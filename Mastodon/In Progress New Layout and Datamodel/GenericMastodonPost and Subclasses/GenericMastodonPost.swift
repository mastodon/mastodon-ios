// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public class GenericMastodonPost: Codable {
    let id: Mastodon.Entity.Status.ID
    let metaData: PostMetadata
    let _legacyEntity: Mastodon.Entity.Status
    
    init(id: Mastodon.Entity.Status.ID, metaData: PostMetadata, _legacyEntity: Mastodon.Entity.Status) {
        self.id = id
        self.metaData = metaData
        self._legacyEntity = _legacyEntity
    }
}

extension GenericMastodonPost {
    struct PostMetrics: Codable {
        let boostCount: Int
        let favoriteCount: Int
        let replyCount: Int
    }
}

extension GenericMastodonPost {
    struct PostActions: Codable {
        var favorited: Bool
        var boosted: Bool
        var muted: Bool
        var bookmarked: Bool
        var pinned: Bool?
    }
}

extension GenericMastodonPost {
    public struct PostContent: Codable {
        let editedAt: Date?
        let language: String?
        let htmlWithEntities: HtmlWithEntities?
        let plainText: String?
        let attachment: PostAttachment?
        let contentWarned: ContentWarned
        let filtered: [Mastodon.Entity.ServerFilterResult]?
        let metrics: PostMetrics
        let myActions: PostActions

        struct HtmlWithEntities: Codable {
            let html: String?
            let mentions: [Mastodon.Entity.Mention]
            let tags: [Mastodon.Entity.Tag]
            let emojis: [Mastodon.Entity.Emoji]
        }

        enum ContentWarned: Codable {
            case nothingToWarn
            case warnAll(reasons: [String])
            case warnMediaAttachmentOnly
        }
    }
    
    enum PostAttachment: Codable {
        case media([Mastodon.Entity.Attachment])
        case poll(Mastodon.Entity.Poll)
        case linkPreviewCard(Mastodon.Entity.Card)
    }
}
    
extension GenericMastodonPost {
    struct PostMetadata: Codable {
        let author: MastodonAccount
        let uriForFediverse: String
        let url: String?
        let privacyLevel: PrivacyLevel?
        let createdAt: Date
        let application: Mastodon.Entity.Application?
    }

    enum PrivacyLevel: Codable {
        case loudPublic
        case quietPublic
        case followersOnly
        case mentionedOnly
    }

    struct InReplyToDetails: Codable {
        let postID: Mastodon.Entity.Status.ID
        let accountID: Mastodon.Entity.Account.ID
    }
}

// MARK: -

protocol FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self
}

protocol FromStatusEntityDerivableOptional {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self?
}

extension GenericMastodonPost.PostMetrics: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        return Self(
            boostCount: status.reblogsCount,
            favoriteCount: status.favouritesCount,
            replyCount: status.repliesCount ?? 0)
    }
}

extension GenericMastodonPost.PostActions: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        return Self(
            favorited: status.favourited ?? false,
            boosted: status.reblogged ?? false, muted: status.muted ?? false,
            bookmarked: status.bookmarked ?? false, pinned: status.pinned)
    }
}

extension GenericMastodonPost.PostContent: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        return Self(
            editedAt: status.editedAt, language: status.language,
            htmlWithEntities: GenericMastodonPost.PostContent.HtmlWithEntities
                .fromStatus(status), plainText: status.text,
            attachment: GenericMastodonPost.PostAttachment.fromStatus(status),
            contentWarned: GenericMastodonPost.PostContent.ContentWarned.fromStatus(
                status), filtered: status.filtered,
            metrics: GenericMastodonPost.PostMetrics.fromStatus(status),
            myActions: GenericMastodonPost.PostActions.fromStatus(status))
    }
}

extension GenericMastodonPost.PostContent.HtmlWithEntities: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        return Self(
            html: status.content?.strippingQuoteInline, mentions: status.mentions, tags: status.tags,
            emojis: status.emojis)
    }
}

extension GenericMastodonPost.PostAttachment: FromStatusEntityDerivableOptional
{
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self? {
        if let attachedPoll = status.poll {
            return .poll(attachedPoll)
        } else if let card = status.card {
            return .linkPreviewCard(card)
        } else if let media = status.mediaAttachments, !media.isEmpty {
            return .media(media)
        } else {
            return nil
        }
    }
}

extension GenericMastodonPost.PostContent.ContentWarned: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        switch (status.sensitive, status.spoilerText) {
        case (false, nil):
            return .nothingToWarn
        case (true, nil):
            return .warnMediaAttachmentOnly
        case (true, _):
            guard let reason = status.spoilerText, !reason.isEmpty else { return .warnMediaAttachmentOnly }
            return .warnAll(reasons: [reason])
        case (_, _):
            guard let reason = status.spoilerText, !reason.isEmpty else { return .nothingToWarn }
            return .warnAll(reasons: [reason])
        }
    }
}

extension GenericMastodonPost.PostMetadata: FromStatusEntityDerivable {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self {
        return Self(
            author: MastodonAccount.fromEntity(status.account), uriForFediverse: status.uri,
            url: status.url,
            privacyLevel: GenericMastodonPost.PrivacyLevel.fromStatus(status),
            createdAt: status.createdAt, application: status.application)
    }
}

extension GenericMastodonPost.PrivacyLevel: FromStatusEntityDerivableOptional {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self? {
        switch status.visibility {
        case .public:
            return .loudPublic
        case .unlisted:
            return .quietPublic
        case .private:
            return .followersOnly
        case .direct:
            return .mentionedOnly
        case ._other(let string):
            assertionFailure("unexpected privacy level \(string)")
            return nil
        case .none:
            return nil
        }
    }
}

extension GenericMastodonPost.InReplyToDetails: FromStatusEntityDerivableOptional {
    static func fromStatus(_ status: Mastodon.Entity.Status) -> Self? {
        guard let post = status.inReplyToID,
            let account = status.inReplyToAccountID
        else { return nil }
        return GenericMastodonPost.InReplyToDetails(postID: post, accountID: account)
    }
}
