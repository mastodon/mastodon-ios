////
////  Status+Property.swift
////  Mastodon
////
////  Created by MainasuK on 2022-1-11.
////
//
//import Foundation
//import CoreGraphics
//import CoreDataStack
//import MastodonSDK
//
//extension Status.Property {
//    init(entity: Mastodon.Entity.Status, domain: String, networkDate: Date) {
//        self.init(
//            identifier: entity.id + "@" + domain,
//            domain: domain,
//            id: entity.id,
//            uri: entity.uri,
//            createdAt: entity.createdAt,
//            editedAt: entity.editedAt,
//            content: entity.content ?? "",
//            visibility: entity.mastodonVisibility,
//            sensitive: entity.sensitive ?? false,
//            spoilerText: entity.spoilerText,
//            reblogsCount: Int64(entity.reblogsCount),
//            favouritesCount: Int64(entity.favouritesCount),
//            repliesCount: Int64(entity.repliesCount ?? 0),
//            url: entity.url,
//            inReplyToID: entity.inReplyToID,
//            inReplyToAccountID: entity.inReplyToAccountID,
//            language: entity.language,
//            text: entity.text,
//            updatedAt: networkDate,
//            deletedAt: nil,
//            attachments: entity.mastodonAttachments,
//            emojis: entity.mastodonEmojis,
//            mentions: entity.mastodonMentions
//        )
//    }
//}
//
//extension Mastodon.Entity.Status {
//    public var mastodonVisibility: MastodonVisibility {
//        let rawValue = visibility?.rawValue ?? ""
//        return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
//    }
//}
//
//extension Mastodon.Entity.Status {
//    public var mastodonAttachments: [MastodonAttachment] {
//        mediaAttachments.mastodonAttachments
//    }
//}
