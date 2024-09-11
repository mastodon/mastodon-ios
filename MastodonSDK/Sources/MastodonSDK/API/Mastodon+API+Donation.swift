// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.API {
    public static func donationsEndpoint(seed: Int, source: String?) -> URL {
        let url = URL(string: "https://api.joinmastodon.org")!
            .appending(path: "v1/donations/campaigns/active")
        
        let locale = Locale.current.identifier
        var queryItems = [
            URLQueryItem(name: "platform", value: "ios"),
            URLQueryItem(name: "locale", value: locale),
            URLQueryItem(name: "seed", value: "\(seed)")
        ]
        #if DEBUG
        queryItems.append(URLQueryItem(name: "environment", value: "staging"))
        #endif
        
        if let source, !source.isEmpty {
            queryItems.append(URLQueryItem(name: "source", value: source))
        }
        
        return url.appending(queryItems: queryItems)
    }
    
    public static func getDonationCampaigns(
        session: URLSession,
        seed: Int,
        source: String?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.DonationCampaign]> {
        let url = donationsEndpoint(seed: seed, source: source)
        let request = Mastodon.API.get(url: url)
        let (data, response) = try await session.data(for: request)
        
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.DonationCampaign].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
