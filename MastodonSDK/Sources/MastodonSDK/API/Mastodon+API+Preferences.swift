//
//  Mastodon+API+Preferences.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 10/14/26.
//

import Foundation

extension Mastodon.API.Preferences {
    
    static func preferencesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("preferences")
    }
    
    /// Preferences
    ///
    /// Represents a user's preferences.
    ///
    /// Since: 2.8.0
    /// #Reference
    /// [Document] (https://docs.joinmastodon.org/methods/preferences/)
    /// - Headers:
    ///    - authorization: user token
    /// - Returns: `Preferences`
    public static func preferences(
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Entity.Preferences {
        let request = Mastodon.API.get(url: preferencesEndpointURL(domain: domain), authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("preferences")
        let (data, response) = try await session.data(for: request)
        return try Mastodon.API.decode(type: Mastodon.Entity.Preferences.self, from: data, response: response)
    }
}
