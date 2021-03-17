//
//  MastodonAttachmentService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-17.
//

import UIKit
import Combine

final class MastodonAttachmentService {
    
    let identifier = UUID()
    
}

extension MastodonAttachmentService: Equatable, Hashable {
    
    static func == (lhs: MastodonAttachmentService, rhs: MastodonAttachmentService) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
}
