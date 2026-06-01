//
//  Status+Property.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreGraphics
import CoreDataStack // Needed until StatusView is gone
import MastodonSDK

extension Mastodon.Entity.Status {
    public var mastodonVisibility: MastodonVisibility {
        let rawValue = visibility?.rawValue ?? ""
        return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
    }
}

extension Mastodon.Entity.Status {
    public var mastodonAttachments: [MastodonAttachment] {
        mediaAttachments.mastodonAttachments
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
