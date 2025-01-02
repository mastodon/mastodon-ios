// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonMeta
import MastodonSDK

extension [Mastodon.Entity.Attachment]? {
    public var mastodonAttachments: [MastodonAttachment] {
        guard let mediaAttachments = self else { return [] }
        
        let attachments = mediaAttachments.compactMap { media -> MastodonAttachment? in
            guard let kind = media.attachmentKind
            else { return nil }

            let width: Int;
            let height: Int;
            let durationMS: Int?;

            if let meta = media.meta,
               let original = meta.original,
               let originalWidth = original.width,
               let originalHeight = original.height {
                width = originalWidth               // audio has width/height
                height = originalHeight
                durationMS = original.duration.map { Int($0 * 1000) }
            }
            else {
                // In case metadata field is missing, use default values.
                width = 32;
                height = 32;
                durationMS = nil;
            }

            let focus: CGPoint? = if let focus = media.meta?.focus {
                CGPoint(x: focus.x, y: focus.y)
            } else {
                nil
            }

            return MastodonAttachment(
                id: media.id,
                kind: kind,
                size: CGSize(width: width, height: height),
                focus: focus,
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
