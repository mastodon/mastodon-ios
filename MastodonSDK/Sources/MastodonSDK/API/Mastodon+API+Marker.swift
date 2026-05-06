//
//  Mastodon+API+Marker.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 2/24/25.
//

import Foundation

extension Mastodon.API.Marker {
    
    static func markersEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("markers")
    }
    
    /// Marker
    ///
    /// Save and restore your position in timelines.
    ///
    /// - Since: 3.0.0
    /// - Version: 3.0.0
    /// # Last Update
    ///   2025/02/24
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/markers/)
    /// - Headers:
    ///   - authorization: Provide this header with Bearer <user_token> to gain authorized access to this API method.
    /// - Parameters:
    ///   - timeline[]: Array of String. Specify the timeline(s) for which markers should be fetched. Possible values: home, notifications. If not provided, an empty object will be returned.
    /// - Returns: `Marker`
    public static func lastReadMarkers(
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Entity.Marker {
        let url = markersEndpointURL(domain: domain)
        let request = Mastodon.API.get(url: url, query: MarkerFetchQuery(), authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("last read markers")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.Marker.self, from: data, response: response)
        return value
    }
    
    public struct MarkerFetchQuery: GetQuery {
        var queryItems: [URLQueryItem]? {
            return ["home", "notifications"].map { URLQueryItem(name: "timeline[]", value: $0)
                }
        }
    }
    
}

