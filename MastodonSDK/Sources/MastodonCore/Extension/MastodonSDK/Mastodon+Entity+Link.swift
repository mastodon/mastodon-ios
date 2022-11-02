//
//  Mastodon+Entity+Link.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import Foundation
import MastodonSDK

extension Mastodon.Entity.Link {
    
    /// the sum of recent 2 days
    public var talkingPeopleCount: Int? {
        return history
            .prefix(2)
            .compactMap { Int($0.accounts) }
            .reduce(0, +)
    }
    
}
