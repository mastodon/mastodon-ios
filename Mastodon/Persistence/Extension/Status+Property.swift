//
//  Status+Property.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreGraphics
import CoreDataStack
import MastodonSDK

extension Status.Property {
    init(entity: Mastodon.Entity.Status, domain: String, networkDate: Date) {
        self.init(
            identifier: entity.id + "@" + domain,
            domain: domain,
            id: entity.id,
            uri: entity.uri,
            createdAt: entity.createdAt,
            content: entity.content ?? "",
            visibility: entity.mastodonVisibility,
            sensitive: entity.sensitive ?? false,
            spoilerText: entity.spoilerText,
            reblogsCount: Int64(entity.reblogsCount),
            favouritesCount: Int64(entity.favouritesCount),
            repliesCount: Int64(entity.repliesCount ?? 0),
            url: entity.url,
            inReplyToID: entity.inReplyToID,
            inReplyToAccountID: entity.inReplyToAccountID,
            language: entity.language,
            text: entity.text,
            updatedAt: networkDate,
            deletedAt: nil,
            attachments: entity.mastodonAttachments,
            emojis: entity.mastodonEmojis,
            mentions: entity.mastodonMentions
        )
    }
}

extension Mastodon.Entity.Status {
    public var mastodonVisibility: MastodonVisibility {
        let rawValue = visibility?.rawValue ?? ""
        return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
    }
}

extension Mastodon.Entity.Status {
    public var mastodonAttachments: [MastodonAttachment] {
        guard let mediaAttachments = mediaAttachments else { return [] }
        
        let attachments = mediaAttachments.compactMap { media -> MastodonAttachment? in
            guard let kind = media.attachmentKind,
                  let meta = media.meta,
                  let original = meta.original,
                  let width = original.width,       // audio has width/height
                  let height = original.height
            else { return nil }
            
            let durationMS: Int? = original.duration.flatMap { Int($0 * 1000) }
            return MastodonAttachment(
                id: media.id,
                kind: kind,
                size: CGSize(width: width, height: height),
                focus: nil,    // TODO:
                blurhash: media.blurhash,
                assetURL: media.url,
                previewURL: media.previewURL,
                textURL: media.textURL,
                durationMS: durationMS,
                altDescription: media.description
            )
        }
        
        return attachments
    }
}

extension Mastodon.Entity.Attachment {
    public var attachmentKind: MastodonAttachment.Kind? {
        switch type {
        case .unknown:  return nil
        case .image:    return .image
        case .gifv:     return .gifv
        case .video:    return .video
        case .audio:    return .audio
        case ._other:   return nil
        }
    }
}
