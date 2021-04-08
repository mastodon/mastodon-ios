//
//  MastodonUser.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonUser.Property {
    init(entity: Mastodon.Entity.Account, domain: String, networkDate: Date) {
        self.init(
            id: entity.id,
            domain: domain,
            acct: entity.acct,
            username: entity.username,
            displayName: entity.displayName,
            avatar: entity.avatar,
            avatarStatic: entity.avatarStatic,
            header: entity.header,
            headerStatic: entity.headerStatic,
            note: entity.note,
            url: entity.url,
            statusesCount: entity.statusesCount,
            followingCount: entity.followingCount,
            followersCount: entity.followersCount,
            locked: entity.locked,
            bot: entity.bot,
            suspended: entity.suspended,
            createdAt: entity.createdAt,
            networkDate: networkDate
        )
    }
}

extension MastodonUser {
    
    var displayNameWithFallback: String {
        return !displayName.isEmpty ? displayName : username
    }
    
    var acctWithDomain: String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + domain
        } else {
            return acct
        }
    }
    
}

extension MastodonUser {
    
    public func headerImageURL() -> URL? {
        return URL(string: header)
    }
    
    public func avatarImageURL() -> URL? {
        return URL(string: avatar)
    }
    
}

extension MastodonUser {
    
    var profileURL: URL {
        if let urlString = self.url,
           let url = URL(string: urlString) {
            return url
        } else {
            return URL(string: "https://\(self.domain)/@\(username)")!
        }
    }
    
    var activityItems: [Any] {
        var items: [Any] = []
        items.append(profileURL)
        return items
    }
}
