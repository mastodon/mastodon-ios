//
//  MastodonUser.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreDataStack
import MastodonSDK
import MastodonMeta

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

extension MastodonUser {
    
    public var profileURL: URL {
        if let urlString = self.url,
           let url = URL(string: urlString) {
            return url
        } else {
            return URL(string: "https://\(self.domain)/@\(username)")!
        }
    }

    public var activityItems: [Any] {
        var items: [Any] = []
        items.append(profileURL)
        return items
    }
    
}

extension MastodonUser {
    public var nameMetaContent: MastodonMetaContent? {
        do {
            let content = MastodonContent(content: displayNameWithFallback, emojis: emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            return metaContent
        } catch {
            assertionFailure()
            return nil
        }
    }
    
    public var bioMetaContent: MastodonMetaContent? {
        guard let note = note else { return nil }
        do {
            let content = MastodonContent(content: note, emojis: emojis.asDictionary)
            let metaContent = try MastodonMetaContent.convert(document: content)
            return metaContent
        } catch {
            assertionFailure()
            return nil
        }
    }
}
