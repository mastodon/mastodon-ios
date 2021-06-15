//
//  Mastodon+Entity+Field.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-25.
//

import Foundation
import MastodonSDK

extension Mastodon.Entity.Field: Equatable {
    public static func == (lhs: Mastodon.Entity.Field, rhs: Mastodon.Entity.Field) -> Bool {
        return lhs.name == rhs.name &&
            lhs.value == rhs.value &&
            lhs.verifiedAt == rhs.verifiedAt
    }
    
    
}
