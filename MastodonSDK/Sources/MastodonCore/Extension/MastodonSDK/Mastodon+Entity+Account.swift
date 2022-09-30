//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import Foundation
import MastodonSDK

extension Mastodon.Entity.Account {
    public var displayNameWithFallback: String {
        if displayName.isEmpty {
            return username
        } else {
            return displayName
        }
    }
}

extension Mastodon.Entity.Account {    
    public func avatarImageURL() -> URL? {
        let string = UserDefaults.shared.preferredStaticAvatar ? avatarStatic ?? avatar : avatar
        return URL(string: string)
    }
    
    public func avatarImageURLWithFallback(domain: String) -> URL {
        return avatarImageURL() ?? URL(string: "https://\(domain)/avatars/original/missing.png")!
    }
}
