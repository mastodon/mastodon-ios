//
//  ComposeStatusAttachmentItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-6-29.
//

import Foundation

enum ComposeStatusAttachmentItem {
    case attachment(attachmentService: MastodonAttachmentService)
}

extension ComposeStatusAttachmentItem: Hashable { }
