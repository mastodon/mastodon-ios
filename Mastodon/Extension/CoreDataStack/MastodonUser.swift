//
//  MastodonUser.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreDataStack
import MastodonSDK

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
