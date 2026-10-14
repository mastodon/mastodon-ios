//
//  APIService+Preferences.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 10/14/26.
//

import MastodonSDK

extension APIService {
    public func preferences(authBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Preferences {
        return try await Mastodon.API.Preferences.preferences(domain: authBox.domain, session: session, authorization: authBox.userAuthorization)
    }
}
