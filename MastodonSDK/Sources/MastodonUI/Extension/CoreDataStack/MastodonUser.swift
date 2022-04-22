//
//  MastodonUser.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import Foundation
import CoreDataStack
import MastodonCommon

extension MastodonUser {

    public var displayNameWithFallback: String {
        return !displayName.isEmpty ? displayName : username
    }

    public var acctWithDomain: String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + domain
        } else {
            return acct
        }
    }

    public var domainFromAcct: String {
        if !acct.contains("@") {
            return domain
        } else {
            let domain = acct.split(separator: "@").last
            return String(domain!)
        }
    }

}

extension MastodonUser {

    public func headerImageURL() -> URL? {
        return URL(string: header)
    }

    public func headerImageURLWithFallback(domain: String) -> URL {
        return URL(string: header) ?? URL(string: "https://\(domain)/headers/original/missing.png")!
    }

    public func avatarImageURL() -> URL? {
        let string = UserDefaults.shared.preferredStaticAvatar ? avatarStatic ?? avatar : avatar
        return URL(string: string)
    }

    public func avatarImageURLWithFallback(domain: String) -> URL {
        return avatarImageURL() ?? URL(string: "https://\(domain)/avatars/original/missing.png")!
    }

}
