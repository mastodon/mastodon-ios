//
//  MastodonAuthentication.swift
//  
//
//  Created by Jed Fox on 2022-11-28.
//

import Foundation
import CoreDataStack
import MastodonSDK

private func decodePreferences(_ data: Data?) -> Mastodon.Entity.Preferences? {
    guard let data else { return nil }
    return try? JSONDecoder().decode(Mastodon.Entity.Preferences.self, from: data)
}
private func encodePreferences(_ preferences: Mastodon.Entity.Preferences?) -> Data? {
    guard let preferences else { return nil }
    return try? JSONEncoder().encode(preferences)
}

extension MastodonAuthentication {
    public var preferences: Mastodon.Entity.Preferences? {
        decodePreferences(preferencesRaw)
    }

    public func update(preferences: Mastodon.Entity.Preferences?) {
        update(preferencesRaw: encodePreferences(preferences))
    }
}

extension MastodonAuthentication.Property {
    public var preferences: Mastodon.Entity.Preferences? {
        decodePreferences(preferencesRaw)
    }

    public init(
        domain: String,
        userID: String,
        username: String,
        appAccessToken: String,
        userAccessToken: String,
        clientID: String,
        clientSecret: String,
        preferences: Mastodon.Entity.Preferences?
    ) {
        self.init(
            domain: domain,
            userID: userID,
            username: username,
            appAccessToken: appAccessToken,
            userAccessToken: userAccessToken,
            clientID: clientID,
            clientSecret: clientSecret,
            preferencesRaw: encodePreferences(preferences)
        )
    }
}
