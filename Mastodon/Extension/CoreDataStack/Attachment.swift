//
//  Attachment.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-2-23.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension Attachment {
    
    var type: Mastodon.Entity.Attachment.AttachmentType {
        return Mastodon.Entity.Attachment.AttachmentType(rawValue: typeRaw) ?? ._other(typeRaw)
    }
    
    var meta: Mastodon.Entity.Attachment.Meta? {
        let decoder = JSONDecoder()
        return metaData.flatMap { try? decoder.decode(Mastodon.Entity.Attachment.Meta.self, from: $0) }
    }
    
}
